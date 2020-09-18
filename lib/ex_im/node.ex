defmodule ExIm.Node do
  @moduledoc ""

  use GenServer
  require Logger

  alias ExIm.Storage

  def start_link(nodes) do
    GenServer.start_link(__MODULE__, nodes, name: __MODULE__)
  end

  def sync_receive(data) do
    GenServer.call(__MODULE__, {:sync_receive, data})
  end

  def init(:dynamic) do
    Storage.init()
    sync(Node.list())
    {:ok, %{nodes: :dynamic}}
  end

  def init(nodes) when is_list(nodes) do
    case node() do
      :nonode@nohost ->
        {:stop, :normal}
      _ ->
        Storage.init()
        Enum.each(nodes, fn node -> Node.monitor(node, true) end)
        active_nodes = Enum.filter(nodes, &Node.connect/1)
        sync(active_nodes)
        {:ok, %{nodes: nodes}}
    end
  end

  def handle_call({:sync_receive, data}, _from, state) do
    Logger.info("sync receive #{inspect(data)}")
    # resolve conflicts
    {:reply, get_local_data(), state}
  end

  def handle_info({:nodedown, node}, state) do
    Logger.info("Node down #{inspect(node)}")
    {:noreply, state}
  end

#  def handle_info({:nodeup, node}, state) do
#    Logger.info("Node up #{inspect(node)}")
#    {:noreply, state}
#  end

  def handle_info(msg, state) do
    Logger.error("Unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp sync(nodes) do
    local_data = get_local_data() |> Enum.sort()
    Enum.map(nodes -- [node()], fn node -> :rpc.call(node, ExIm.Node, :sync_receive, [get_local_data()]) end)
    |> Enum.each(fn node_data -> resolve(local_data, Enum.sort(node_data)) end)
  end

  defp get_local_data() do
    Storage.read_all()
  end

  defp resolve([x | local], [x | remote]) do
    resolve(local, remote)
  end

  defp resolve([{table, key, _, true} | local], [{table, key, _, false} | remote]) do
    resolve(local, remote)
  end

  defp resolve([{table, key, _, false} | local], [{table, key, _, true} | remote]) do
    Storage.delete(table, key)
    resolve(local, remote)
  end

  defp resolve([x | local], [y | remote]) when x < y do
    resolve(local, [y | remote])
  end

  defp resolve(local, [{table, key, value, false} | remote]) do
    Storage.write(table, key, value)
    resolve(local, remote)
  end

  defp resolve(local, [_ | remote]) do
    resolve(local, remote)
  end

  defp resolve(_, []) do
    IO.inspect(get_local_data())
    :ok
  end
end

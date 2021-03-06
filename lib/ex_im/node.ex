defmodule ExIm.Node do
  @moduledoc ""

  use GenServer
  require Logger

  alias ExIm.Storage

  def start_link(nodes) do
    GenServer.start_link(__MODULE__, nodes, name: __MODULE__)
  end

  def write(table, key, value) do
    GenServer.call(__MODULE__, {:write, table, key, value})
  end

  def read(table, key) do
    GenServer.call(__MODULE__, {:read, table, key})
  end

  def delete(table, key) do
    GenServer.call(__MODULE__, {:delete, table, key})
  end

  def list(table) do
    GenServer.call(__MODULE__, {:list, table})
  end

  def backup() do
    GenServer.call(__MODULE__, :backup)
  end

  def restore(data) do
    GenServer.call(__MODULE__, {:restore, data})
  end

  def sync_receive(data) do
    GenServer.call(__MODULE__, {:sync_receive, data})
  end

  def init(%{env: env, nodes: :dynamic} = arg) do
    Storage.init()
    if env == :distributed, do: sync(Node.list())
    {:ok, arg}
  end

  def init(%{env: env, nodes: nodes} = arg) when is_list(nodes) do
    Storage.init()

    if env == :distributed do
      Enum.each(nodes, fn node -> Node.monitor(node, true) end)
      active_nodes = Enum.filter(nodes, &Node.connect/1)
      sync(active_nodes)
    end

    {:ok, arg}
  end

  def handle_call({:sync_receive, data}, _from, state) do
    Logger.info("sync receive #{inspect(data)}")
    resolve(get_local_data(), data)
    {:reply, get_local_data(), state}
  end

  def handle_call({:write, table, key, value}, _from, %{nodes: :dynamic} = state) do
    Storage.write(table, key, value)

    Enum.each(Node.list(), fn node ->
      :rpc.call(node, Storage, :write, [table, key, value])
    end)

    {:reply, :ok, state}
  end

  def handle_call({:write, table, key, value}, _from, %{nodes: nodes} = state)
      when is_list(nodes) do
    Enum.each(nodes, fn node -> :rpc.call(node, Storage, :write, [table, key, value]) end)
    {:reply, :ok, state}
  end

  def handle_call({:read, table, key}, _from, state) do
    {:reply, Storage.read(table, key), state}
  end

  def handle_call({:delete, table, key}, _from, %{nodes: :dynamic} = state) do
    Enum.each([node() | Node.list()], fn node ->
      :rpc.call(node, Storage, :delete, [table, key])
    end)

    {:reply, :ok, state}
  end

  def handle_call({:delete, table, key}, _from, %{nodes: nodes} = state) when is_list(nodes) do
    Enum.each(nodes, fn node -> :rpc.call(node, Storage, :delete, [table, key]) end)
    {:reply, :ok, state}
  end

  def handle_call({:list, table}, _from, state) do
    {:reply, Storage.list(table), state}
  end

  def handle_call(:backup, _from, state) do
    {:reply, Storage.backup(), state}
  end

  def handle_call({:restore, data}, _from, %{nodes: :dynamic} = state) do
    Storage.restore(data)
    Enum.each(Node.list(), fn node -> :rpc.call(node, Storage, :restore, [data]) end)
    {:reply, :ok, state}
  end

  def handle_call({:restore, data}, _from, %{nodes: nodes} = state) when is_list(nodes) do
    Enum.each(nodes, fn node -> :rpc.call(node, Storage, :restore, [data]) end)
    {:reply, :ok, state}
  end

  def handle_info({:nodedown, node}, state) do
    Logger.info("Node down #{inspect(node)}")
    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    Logger.info("Node up #{inspect(node)}")
    :rpc.call(node, ExIm.Node, :sync_receive, [get_local_data()])
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("Unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp sync(nodes) do
    Logger.info("Sync nodes")
    local_data = get_local_data() |> Enum.sort()

    Enum.map(nodes -- [node()], fn node ->
      :rpc.call(node, ExIm.Node, :sync_receive, [get_local_data()])
    end)
    |> Enum.filter(fn
      {:badrpc, _} -> false
      _ -> true
    end)
    |> Enum.each(fn node_data -> resolve(local_data, Enum.sort(node_data)) end)
  end

  defp get_local_data() do
    Storage.read_all()
  end

  defp resolve([x | local], [x | remote]) do
    resolve(local, remote)
  end

  defp resolve([{table, key, {_, lversion, _}} | local], [{table, key, {_, rversion, _}} | remote])
       when lversion > rversion do
    resolve(local, remote)
  end

  defp resolve([{table, key, {_, lversion, _}} | local], [
         {table, key, {rvalue, rversion, rdeleted}} | remote
       ])
       when lversion < rversion do
    Storage.raw_write(table, key, rvalue, rversion, rdeleted)
    resolve(local, remote)
  end

  defp resolve([{table, key, {_, version, _}} | local], [{table, key, {_, version, _}} | remote]) do
    Logger.error("Value confilct table #{inspect(table)} key #{inspect(key)}")
    resolve(local, remote)
  end

  defp resolve([x | local], [y | remote]) when x < y do
    resolve(local, [y | remote])
  end

  defp resolve(local, [{table, key, {value, version, deleted}} | remote]) do
    Storage.raw_write(table, key, value, version, deleted)
    resolve(local, remote)
  end

  defp resolve(local, [_ | remote]) do
    resolve(local, remote)
  end

  defp resolve(_, []) do
    :ok
  end
end

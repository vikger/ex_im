defmodule ExIm.Storage.Process do
  use GenServer

  def init() do
    start_link(nil)
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def read_all() do
    GenServer.call(__MODULE__, :read_all)
  end

  def tables() do
    GenServer.call(__MODULE__, :tables)
  end

  def write(table, key, value) do
    GenServer.call(__MODULE__, {:write, table, key, value})
  end

  def raw_write(table, key, value, version, deleted) do
    GenServer.call(__MODULE__, {:raw_write, table, key, value, version, deleted})
  end

  def read(table, key) do
    GenServer.call(__MODULE__, {:read, table, key})
  end

  def delete(table, key) do
    GenServer.call(__MODULE__, {:delete, table, key})
  end

  def handle_call(:read_all, _from, state) do
    reply =
      Enum.map(Map.keys(state), fn {table, key} ->
        {table, key, Enum.at(state[{table, key}], 0)}
      end)

    {:reply, reply, state}
  end

  def handle_call(:tables, _from, state) do
    reply =
      Enum.map(Map.keys(state), fn {table, _key} -> table end)
      |> Enum.uniq()

    {:reply, reply, state}
  end

  def handle_call({:write, table, key, value}, _from, state) do
    new_state =
      case state[{table, key}] do
        nil ->
          Map.put(state, {table, key}, [{value, 1, false}])

        [{old_value, version, _deleted} | values] ->
          Map.put(state, {table, key}, [
            {value, version + 1, false},
            {old_value, version, true} | values
          ])
      end

    {:reply, :ok, new_state}
  end

  def handle_call({:raw_write, table, key, value, version, deleted}, _from, state) do
    new_state = Map.put(state, {table, key}, [{value, version, deleted}])
    {:reply, :ok, new_state}
  end

  def handle_call({:read, table, key}, _form, state) do
    reply =
      case state[{table, key}] do
        nil ->
          {:error, :not_found}

        [{value, _version, false} | _] ->
          {:ok, value}

        [{_value, _Version, true} | _] ->
          {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:delete, table, key}, _from, state) do
    new_state =
      case state[{table, key}] do
        nil ->
          state

        [{_value, _version, true} | _] ->
          state

        [{value, version, false} | values] ->
          Map.put(state, {table, key}, [{value, version, true} | values])
      end

    {:reply, :ok, new_state}
  end
end

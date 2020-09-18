defmodule ExIm.Storage.Process do
  def init() do
    Process.register(spawn(fn -> loop() end), __MODULE__)
  end

  def read_all() do
    call(:read_all)
  end

  def tables() do
    call(:tables)
  end

  def write(table, key, value) do
    call({:write, table, key, value})
  end

  def read(table, key) do
    call({:read, table, key})
  end

  def delete(table, key) do
    call({:delete, table, key})
  end

  def call(request) do
    send(__MODULE__, {self(), request})

    receive do
      {:storage_process, reply} -> reply
    end
  end

  def send_reply(pid, reply) do
    send(pid, {:storage_process, reply})
  end

  def loop() do
    receive do
      {from, :read_all} ->
        reply =
          Process.get()
          |> Enum.map(fn {{table, key}, values} ->
            Enum.map(values, fn {value, deleted} -> {table, key, value, deleted} end)
          end)
          |> List.flatten()

        send_reply(from, reply)
        loop()

      {from, :tables} ->
        reply =
          Process.get()
          |> Enum.map(fn {{table, _}, _} -> table end)
          |> Enum.uniq()

        send_reply(from, reply)
        loop()

      {from, {:write, table, key, value}} ->
        Process.get({table, key})
        |> case do
          nil ->
            Process.put({table, key}, [{value, false}])

          values ->
            new_values =
              Enum.reduce(values, [], fn
                {v, false}, acc -> [{v, true} | acc]
                deleted, acc -> [deleted | acc]
              end)

            Process.put({table, key}, [{value, false} | new_values])
        end

        send_reply(from, :ok)
        loop()

      {from, {:read, table, key}} ->
        reply =
          Process.get({table, key})
          |> case do
            nil ->
              {:error, :not_found}

            values ->
              Enum.filter(values, fn
                {_, false} -> true
                _ -> false
              end)
              |> case do
                [{value, _}] ->
                  {:ok, value}

                [] ->
                  {:error, :not_found}
              end
          end

        send_reply(from, reply)
        loop()

      {from, {:delete, table, key}} ->
        Process.get({table, key})
        |> case do
          nil ->
            :noop

          values ->
            new_values =
              Enum.reduce(values, [], fn
                {v, false}, acc ->
                  [{v, true} | acc]

                other, acc ->
                  [other | acc]
              end)

            Process.put({table, key}, new_values)
        end

        send_reply(from, :ok)
        loop()
    end
  end
end

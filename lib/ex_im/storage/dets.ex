defmodule ExIm.Storage.Dets do
  def init_tables(tables) do
    Enum.each(tables, fn table ->
      {:ok, _} = :dets.open_file(full_table_name(table), type: :bag)
    end)
  end

  def read_all() do
    Enum.map(tables(), fn table ->
      :dets.foldl(
        fn {key, value, version, deleted}, acc ->
          [{table, key, {value, version, deleted}} | acc]
        end,
        [],
        full_table_name(table)
      )
    end)
    |> Enum.concat()
  end

  def tables() do
    Application.get_env(:ex_im, :tables, [])
  end

  def write(table, key, value) do
    case raw_read(table, key) do
      {:error, :not_found} ->
        :dets.insert(full_table_name(table), {key, value, 1, false})

      {old_value, version, true} ->
        :dets.delete_object(full_table_name(table), {key, old_value, version, true})
        :dets.insert(full_table_name(table), {key, value, version + 1, false})

      {old_value, version, false} ->
        :dets.delete_object(full_table_name(table), {key, old_value, version, false})
        :dets.insert(full_table_name(table), {key, value, version + 1, false})
    end
  end

  def read(table, key) do
    case raw_read(table, key) do
      {value, _, false} ->
        {:ok, value}

      _ ->
        {:error, :not_found}
    end
  end

  def delete(table, key) do
    case raw_read(table, key) do
      {value, version, false} ->
        :dets.delete(full_table_name(table), key)
        :dets.insert(full_table_name(table), {key, value, version, true})
        :ok

      _ ->
        :ok
    end
  end

  def list(table) do
    values =
      read_all()
      |> Enum.filter(fn
        {^table, _key, {_value, _, false}} -> true
        _ -> false
      end)
      |> Enum.map(fn {_table, key, {value, _, _}} -> {key, value} end)

    {:ok, values}
  end

  def backup() do
    {:ok, read_all() |> :erlang.term_to_binary()}
  end

  def restore(data) do
    try do
      term_data = :erlang.binary_to_term(data)

      tables()
      |> Enum.each(fn table -> :dets.delete_all_objects(full_table_name(table)) end)

      term_data
      |> Enum.each(fn {table, key, {value, version, deleted}} ->
        :dets.insert(full_table_name(table), {key, value, version, deleted})
      end)
    rescue
      _error ->
        {:error, "invalid backup"}
    end
  end

  defp full_table_name(table) do
    to_charlist(table) ++ '_' ++ to_charlist(node())
  end

  defp find_latest([{_, value, version, deleted} | values]) do
    find_latest(values, {value, version, deleted})
  end

  defp find_latest([{_, new_value, new_version, new_deleted} | values], {_, old_version, _})
       when new_version > old_version do
    find_latest(values, {new_value, new_version, new_deleted})
  end

  defp find_latest([_ | values], value) do
    find_latest(values, value)
  end

  defp find_latest([], value) do
    value
  end

  defp raw_read(table, key) do
    case :dets.lookup(full_table_name(table), key) do
      [] ->
        {:error, :not_found}

      values when is_list(values) ->
        find_latest(values)
    end
  end
end

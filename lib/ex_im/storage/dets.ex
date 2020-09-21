defmodule ExIm.Storage.Dets do
  def init_tables(tables) do
    Enum.each(tables, fn table ->
      {:ok, _} = :dets.open_file(full_table_name(table), type: :bag)
    end)
  end

  def write(table, key, value) do
    :dets.insert(full_table_name(table), {key, value})
  end

  def read(table, key) do
    :dets.lookup(full_table_name(table), key)
  end

  def delete(table, key) do
    :dets.delete(full_table_name(table), key)
  end

  def read_all() do
    Enum.map(Application.get_env(:ex_im, :tables, []), fn table ->
      :dets.foldl(fn item, acc -> [item | acc] end, [], full_table_name(table))
    end)
    |> Enum.concat()
  end

  defp full_table_name(table) do
    to_charlist(table) ++ '_' ++ to_charlist(node())
  end
end

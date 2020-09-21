defmodule ExImTest do
  use ExUnit.Case
  doctest ExIm

  test "write to random nodes" do
    nodes = LocalCluster.start_nodes("my-cluster", 3)
    [table | _] = Application.get_env(:ex_im, :tables, [])
    records = 10000

    1..records
    |> Enum.each(fn n ->
      node = select_random_node(nodes)
      :rpc.call(node, ExIm, :write, [table, n, n])
    end)

    lengths =
      Enum.map(nodes, fn node -> :rpc.call(node, ExIm.Storage, :read_all, []) |> length() end)

    assert Enum.all?(lengths, fn l -> l == records end)
  end

  defp select_random_node(nodes) do
    Enum.at(nodes, :rand.uniform(length(nodes)) - 1)
  end
end

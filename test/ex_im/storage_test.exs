defmodule ExIm.StorageTest do
  use ExUnit.Case

  test "something with a required cluster" do
    nodes = LocalCluster.start_nodes("my-cluster", 3)
  end
end

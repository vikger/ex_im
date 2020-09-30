defmodule ExIm.StorageTest do
  use ExUnit.Case

  alias ExIm.Storage.{Dets, Process}

  setup_all do
    Application.ensure_all_started(:ex_im)
  end

  test "process storage" do
    run_test(Process)
  end

  test "dets storage" do
    run_test(Dets)
  end

  defp run_test(module) do
    module.init_tables([:test_table])
    module.delete(:test_table, :a)
    module.write(:test_table, :b, :c)
    assert [{:test_table, :b, {:c, _, false}}] = module.read_all()
    assert {:ok, :c} = module.read(:test_table, :b)
    assert {:error, :not_found} = module.read(:test_table, :c)
    module.delete(:test_table, :b)
    assert [{:test_table, :b, {:c, _, true}}] = module.read_all()
    module.write(:test_table, :b, :c)
    assert [{:test_table, :b, {:c, _, false}}] = module.read_all()
    module.write(:test_table, :b, :d)
    assert [{:test_table, :b, {:d, _, false}}] = module.read_all()
    assert {:ok, [{:test_table, :b, :d}]} = module.list(:test_table)
  end
end

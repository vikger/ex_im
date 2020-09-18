defmodule ExIm.Storage do
  @moduledoc ""

  def init() do
    backend().init()
  end

  def read_all() do
    backend().read_all()
  end

  def tables() do
    backend().tables()
  end

  def write(table, key, value) do
    backend().write(table, key, value)
  end

  def read(table, key) do
    backend().read(table, key)
  end

  def delete(table, key) do
    backend().delete(table, key)
  end

  defp backend() do
    ExIm.Storage.Process
  end
end

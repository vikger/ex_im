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

  def raw_write(table, key, value, version, deleted) do
    backend().raw_write(table, key, value, version, deleted)
  end

  def read(table, key) do
    backend().read(table, key)
  end

  def delete(table, key) do
    backend().delete(table, key)
  end

  defp backend() do
    Application.get_env(:ex_im, :backend)
  end
end

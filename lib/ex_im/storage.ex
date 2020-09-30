defmodule ExIm.Storage do
  @moduledoc ""

  def init() do
    Application.get_env(:ex_im, :tables)
    |> backend().init_tables()
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

  def list(table) do
    backend().list(table)
  end

  def backup() do
    backend().backup()
  end

  def restore(data) do
    backend().restore(data)
  end

  defp backend() do
    Application.get_env(:ex_im, :backend)
  end
end

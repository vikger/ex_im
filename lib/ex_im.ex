defmodule ExIm do
  @moduledoc """
  ExIm external API.
  """

  alias ExIm.{Node, Storage}

  def write(table, key, value) do
    Node.write(table, key, value)
  end

  def read(table, key) do
    Node.read(table, key)
  end

  def delete(table, key) do
    Node.delete(table, key)
  end

  def list(table) do
    Storage.list(table)
  end

  def tables() do
    Storage.tables()
  end
end

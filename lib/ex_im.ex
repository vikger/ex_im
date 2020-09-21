defmodule ExIm do
  @moduledoc """
  ExIm external API.
  """

  alias ExIm.Node

  def write(table, key, value) do
    Node.write(table, key, value)
  end

  def read(table, key) do
    Node.read(table, key)
  end

  def delete(table, key) do
    Node.delete(table, key)
  end
end

defmodule ExImTest do
  use ExUnit.Case
  doctest ExIm

  test "greets the world" do
    assert ExIm.hello() == :world
  end
end

defmodule ExserverTest do
  use ExUnit.Case
  doctest Exserver

  test "greets the world" do
    assert Exserver.hello() == :world
  end
end

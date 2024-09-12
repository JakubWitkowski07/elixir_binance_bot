defmodule ElixirBinanceBotTest do
  use ExUnit.Case
  doctest ElixirBinanceBot

  test "greets the world" do
    assert ElixirBinanceBot.hello() == :world
  end
end

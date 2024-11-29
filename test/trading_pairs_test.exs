defmodule ElixirBinanceBot.TradingPairsTest do
  use ElixirBinanceBot.RepoCase

  import ElixirBinanceBot.TestHelpers
  alias ElixirBinanceBot.TradingPairs

  # setup do
  #   :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  #   :ok = Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
  #   :ok
  # end

  test "example test" do
    assert true
  end

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{symbol: "BTCUSDT", last_price: 1234.56}
      changeset = TradingPairs.changeset(%TradingPairs{}, attrs)

      assert changeset.valid?
    end

    test "invalid changeset when required fields are missing" do
      attrs = %{last_price: 1234.56}
      changeset = TradingPairs.changeset(%TradingPairs{}, attrs)

      refute changeset.valid?
      assert %{symbol: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "insert_trading_pair/1" do
    test "inserts a valid trading pair" do
      assert {:ok, _trading_pair} = TradingPairs.insert_trading_pair("BTCUSDT")
      assert Repo.get_by(TradingPairs, symbol: "BTCUSDT")
    end

    test "fails for duplicate symbols" do
      {:ok, _} = TradingPairs.insert_trading_pair("BTCUSDT")
      {:error, changeset} = TradingPairs.insert_trading_pair("BTCUSDT")

      assert %{symbol: ["has already been taken"]} = errors_on(changeset)
    end
  end

  describe "fetch_trading_symbols/0" do
    test "fetches trading symbols from the database" do
      Repo.insert!(%TradingPairs{symbol: "BTCUSDT", last_price: 1234.56})
      Repo.insert!(%TradingPairs{symbol: "ETHUSDT", last_price: 234.56})

      assert TradingPairs.fetch_trading_symbols() == ["BTCUSDT", "ETHUSDT"]
    end

    test "returns an empty list when no trading pairs exist" do
      assert TradingPairs.fetch_trading_symbols() == []
    end
  end
end

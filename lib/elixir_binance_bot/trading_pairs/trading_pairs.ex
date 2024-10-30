defmodule ElixirBinanceBot.TradingPairs.TradingPair do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trading_pairs" do
    field(:symbol, :string)
    field(:last_price, :float)
    timestamps()
  end

  def changeset(trading_pair, attrs) do
    trading_pair
    |> cast(attrs, [:symbol, :last_price])
    |> validate_required([:symbol])
  end
end

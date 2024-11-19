defmodule ElixirBinanceBot.TradingPairs do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias ElixirBinanceBot.Repo
  alias __MODULE__

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

  def insert_trading_pair(trading_pair) do
    attrs = %{symbol: trading_pair}
    %TradingPairs{}
    |> TradingPairs.changeset(attrs)
    |> Repo.insert()
  end

  def fetch_trading_symbols do
    query =
      from(trading_pair in TradingPairs,
        select: trading_pair.symbol
      )

    Repo.all(query)
  end
end

defmodule TradingApp.TradingPairs do
  @moduledoc """
  Handles operations related to trading pairs.

  This module provides functionality for managing trading pairs in the system,
  including insertion, validation, and retrieval. The trading pairs are stored
  in the `trading_pairs` database table.

  ## Schema Fields

    - `:symbol` - The unique trading pair symbol (e.g., "BTCUSDT").
    - `:last_price` - The last recorded price for the trading pair.
    - Timestamps (`:inserted_at` and `:updated_at`).
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias TradingApp.Repo
  alias __MODULE__

  schema "trading_pairs" do
    field(:symbol, :string)
    field(:last_price, :float)
    timestamps()
  end

  @doc """
  Generates a changeset for the `TradingPairs` schema.

  ## Parameters

    - `trading_pair` - An existing `%TradingPairs{}` struct or an empty struct.
    - `attrs` - A map of attributes to apply.
  """
  def changeset(trading_pair, attrs) do
    trading_pair
    |> cast(attrs, [:symbol, :last_price])
    |> validate_required([:symbol])
    |> unique_constraint(:symbol, message: "has already been taken")
  end

  @doc """
  Inserts a new trading pair into the database.

  This function takes a symbol (string) representing a trading pair and inserts it
  into the database if it does not already exist.

  ## Parameters

    - `trading_pair` - A string representing the trading pair (e.g., "BTCUSDT").

  ## Returns

    - `{:ok, %TradingPairs{}}` - If the insertion is successful.
    - `{:error, %Ecto.Changeset{}}` - If the insertion fails due to validation errors.

  ## Examples

      iex> TradingApp.TradingPairs.insert_trading_pair("BTCUSDT")
      {:ok, %TradingPairs{}}

      iex> TradingApp.TradingPairs.insert_trading_pair("BTCUSDT")
      {:error, %Ecto.Changeset{errors: [symbol: {"has already been taken", ...}]}}
  """
  def insert_trading_pair(trading_pair) do
    attrs = %{symbol: trading_pair}

    %TradingPairs{}
    |> TradingPairs.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Fetches all trading pair symbols from the database.

  ## Returns

    - A list of strings, each representing a trading pair symbol.

  ## Examples

      iex> TradingApp.TradingPairs.fetch_trading_symbols()
      ["BTCUSDT", "ETHUSDT", "SOLUSDT"]
  """
  def fetch_trading_symbols do
    query =
      from(trading_pair in TradingPairs,
        select: trading_pair.symbol
      )

    Repo.all(query)
  end
end

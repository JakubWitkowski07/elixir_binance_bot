defmodule BinanceTradingBot.Operations do
  @moduledoc """
  Module for interacting with Binance API for trade operations.
  """

  @doc """
  Fetches actual price for given `symbol` (pair).

  ## Parameters

    - `symbol`: A string representing the trading pair symbol (e.g., "BTCUSDT", "ETHUSDT").

  ## Returns

    - `{:ok, price}`: Returns `{:ok, price}` on success, where `price` is a string representing the latest price of the given trading pair.
    - `{:error, reason}`: Returns `{:error, reason}` on failure, with a descriptive error message.

  ## Examples

      iex> BinanceTradingBot.Client.get_price("BTCUSDT")
      {:ok, "29150.55000000"}

      iex> BinanceTradingBot.Client.get_price("ETHUSDT")
      {:ok, "1840.67000000"}

      iex> BinanceTradingBot.Client.get_price("INVALIDPAIR")
      {:error, "Error: 400 - {\"code\":-1121,\"msg\":\"Invalid symbol.\"}"}

  """
  def check_price(symbol) do
    url = "https://api.binance.com/api/v3/ticker/price?symbol=#{symbol}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"price" => price}} ->
            {:ok, price}
          {:error, _error} ->
            {:error, "Failed to parse response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Error: #{status_code} - #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end
end

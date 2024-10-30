defmodule ElixirBinanceBot.PriceChecker do
  use GenServer

  alias ElixirBinanceBot.Repo
  alias ElixirBinanceBot.TradingPairs.TradingPair

  @check_interval :timer.seconds(15)

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_price_check()
    {:ok, state}
  end

  @impl true
  # Function to fetch prices for all trading pairs and update them in the database
  def handle_info(:check_prices, state) do
    check_and_update_prices()
    schedule_price_check()
    {:noreply, state}
  end

  # Helper function to fetch prices for each pair and update the database
  defp check_and_update_prices do
    Repo.all(TradingPair)
    |> Enum.each(&fetch_and_update_price/1)
  end

  # Fetches current price and updates the trading pair in the database
  defp fetch_and_update_price(pair) do
    case fetch_price(pair.symbol) do
      {:ok, price} ->
        Repo.update!(Ecto.Changeset.change(pair, last_price: price))

      {:error, reason} ->
        IO.puts("Failed to fetch price for #{pair.symbol}: #{reason}")
    end
  end

  # Fetch price from an API (replace with real API call)
  defp fetch_price(symbol) do
    case BinanceApiClient.check_price(symbol) do
    {:ok, price} ->
      {:ok, price}
    {:error, reason} ->
      {:error, reason}
    end
  end

  # Schedule the next price check
  defp schedule_price_check do
    Process.send_after(self(), :check_prices, @check_interval)
  end
end

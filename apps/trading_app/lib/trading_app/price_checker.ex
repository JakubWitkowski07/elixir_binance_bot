defmodule TradingApp.PriceChecker do
  alias Phoenix.PubSub
  use GenServer

  @doc """
  Starts the `PriceChecker` GenServer.

  ## Examples

      {:ok, pid} = TradingApp.PriceChecker.start_link()
  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Fetches the actual price for the given trading pair.

  ## Parameters

  - `trading_pair` (string): The symbol of the trading pair (e.g., `"BTCUSDT"`).

  ## Returns

  - `{:ok, actual_price}`: The price fetched from the Binance API.
  - `{:nok, reason}`: The reason for the failure, if fetching the price was unsuccessful.

  ## Examples

      iex> TradingApp.PriceChecker.fetch_actual_price("ETHUSDT")
      {:ok, 3572.5}

  """
  def fetch_actual_price(trading_pair) do
    GenServer.call(__MODULE__, {:fetch_actual_price, trading_pair})
  end

  def update_state do
    GenServer.cast(__MODULE__, {:update_state})
  end

  @impl true
  @doc """
  Initializes the `PriceChecker` state.

  This function sets up the GenServer with its initial state.
  """
  def init(_state) do
    state = TradingApp.TradingPairs.fetch_trading_symbols()
    schedule_fetch_prices()
    {:ok, state}
  end

  @impl true
  @doc """
  Handles the `{:fetch_actual_price, trading_pair}` call.

  Fetches the current price for the given trading pair by calling the Binance API and returns the result.

  ## Parameters

  - `trading_pair`: The trading pair for which the price is being fetched.

  ## Returns

  - `{:reply, {:ok, actual_price}, state}`: On success, returns the price and keeps the state unchanged.
  - `{:reply, {:nok, reason}, state}`: On failure, returns the error reason and keeps the state unchanged.
  """
  def handle_call({:fetch_actual_price, trading_pair}, _from, state) do
    case BinanceApiClient.check_price(trading_pair) do
      {:ok, actual_price} ->
        {:reply, {:ok, actual_price}, state}

      {:error, reason} ->
        {:reply, {:nok, reason}, state}
    end
  end

  @impl true
  def handle_cast({:update_state}, _state) do
    state = TradingApp.TradingPairs.fetch_trading_symbols()
    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch_prices, state) do
    # Fetch actual prices for all trading pairs
    case BinanceApiClient.check_prices(state) do
      {:ok, prices_table} ->
        IO.inspect(prices_table, label: "Fetched Prices")
        PubSub.broadcast(TradingInterface.PubSub, "price_updates", prices_table)
      {:error, reason} ->
        IO.puts("Error fetching prices: #{inspect(reason)}")
    end


    # Reschedule the next fetch
    schedule_fetch_prices()

    {:noreply, state}
  end

  # Schedules the next fetch_actual_prices call
  defp schedule_fetch_prices do
    Process.send_after(self(), :fetch_prices, 5_000) # 1 second
  end
end

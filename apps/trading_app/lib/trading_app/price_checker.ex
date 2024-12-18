defmodule TradingApp.PriceChecker do
  require Logger
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

  @doc """
  Updates actual state of GenServer with actual trading pairs fetched from trading_pairs table in database.

  ## Returns

  - `{:noreply, state}`: Trading pairs table fetched from database.

  ## Examples

      iex> TradingApp.PriceChecker.update_state()
      {:noreply, state}

  """
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
  def handle_call({:fetch_actual_price, trading_pair}, _from, state) do
    case BinanceApiClient.check_price(trading_pair) do
      {:ok, actual_price} ->
        {:reply, {:ok, actual_price}, state}

      {:error, reason} ->
        {:reply, {:nok, reason}, state}
    end
  end

  @impl true
  # Function called after updating the trading pairs table in database to update state for prices table.
  def handle_cast({:update_state}, _state) do
    state = TradingApp.TradingPairs.fetch_trading_symbols()
    {:noreply, state}
  end

  @impl true
  # Function called in loop to update stete with actual prices of trading pairs.
  # Updated prices table is broadcasted to TradingInterface for refreshing data in LiveView page.
  def handle_info(:fetch_prices, state) do
    # Fetch actual prices for all trading pairs
    case BinanceApiClient.check_prices(state) do
      {:ok, prices_table} ->
        PubSub.broadcast(TradingInterface.PubSub, "price_updates", prices_table)

      {:error, reason} ->
        Logger.warning("Error fetching prices: #{inspect(reason)}")
    end

    # Reschedule the next fetch
    schedule_fetch_prices()
    {:noreply, state}
  end

  # Schedules the next prices fetching after set time.
  defp schedule_fetch_prices do
    # 5 seconds
    Process.send_after(self(), :fetch_prices, 5_000)
  end
end

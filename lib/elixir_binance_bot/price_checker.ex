defmodule ElixirBinanceBot.PriceChecker do
  use GenServer

  @doc """
  Starts the `PriceChecker` GenServer.

  ## Examples

      {:ok, pid} = ElixirBinanceBot.PriceChecker.start_link()
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

      iex> ElixirBinanceBot.PriceChecker.fetch_actual_price("ETHUSDT")
      {:ok, 3572.5}

  """
  def fetch_actual_price(trading_pair) do
    GenServer.call(__MODULE__, {:fetch_actual_price, trading_pair})
  end

  @impl true
  @doc """
  Initializes the `PriceChecker` state.

  This function sets up the GenServer with its initial state.
  """
  def init(state) do
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
end

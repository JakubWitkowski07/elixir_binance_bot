defmodule ElixirBinanceBot.PriceChecker do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def fetch_actual_price(trading_pair) do
    GenServer.call(__MODULE__, {:fetch_actual_price, trading_pair})
  end

  @impl true
  def init(state) do
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
end

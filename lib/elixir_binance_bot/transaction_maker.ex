defmodule ElixirBinanceBot.TransactionMaker do
  use GenServer
  require Logger

  alias ElixirBinanceBot.{Transactions, TransactionSlots, NumberFormatter}
  import BinanceApiClient

  # hardcoded sell factor - in future user will have possbility to set sell factor, it will be stored in user's database
  @sell_factor 1.015

  @doc """
  Starts the `TransactionMaker` GenServer.

  ## Examples

      {:ok, pid} = ElixirBinanceBot.TransactionMaker.start_link()

  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Creates a buy transaction for the given trading pair.

  ## Parameters

  - `trading_pair` (string): The symbol of the trading pair (e.g., `"BTCFDUSD"`).
  - `budget` (float): The budget for the buy order.
  - `transaction_slot_id` (integer): The ID of the transaction slot to associate with this order.

  ## Returns

  - `{:ok, :transaction_done}` if the transaction is successful.
  - `{:nok, :transaction_not_done, reason}` if the transaction fails.

  ## Examples

      iex> ElixirBinanceBot.TransactionMaker.make_buy("BTCFDUSD", 10.42416, 1)
      {:ok, :transaction_done}

      iex> ElixirBinanceBot.TransactionMaker.make_buy("notexistingsymbol", 10.42416, 1)
      {:nok, :transaction_not_done, "Request failed with status code 400. Body:{\"code\":-1100,\"msg\":\"Illegal
      characters found in parameter 'symbol'; legal range is '^[A-Z0-9-_.]{1,20}$'.\"}"}

  """
  def make_buy(trading_pair, budget, transaction_slot_id) do
    GenServer.call(__MODULE__, {:make_buy, trading_pair, budget, transaction_slot_id})
  end

  @doc """
  Creates a sell transaction for the given transaction.

  ## Parameters

  - `transaction` (map): A map containing details of the transaction fetched from database to sell.
    Must include keys: `:amount`, `:symbol`, `:real_bought_for`, and `:transaction_slot_id`.

  ## Returns

  - `{:ok, :transaction_done}` if the transaction is successful.
  - `{:nok, :transaction_not_done, reason}` if the transaction fails.

  ## Examples

      iex> transaction = %{amount: 0.5, symbol: "BTCFDUSD", real_bought_for: 500.0, transaction_slot_id: 1}
      iex> ElixirBinanceBot.TransactionMaker.make_sell(transaction)
      {:ok, :transaction_done}

      iex> transaction = %{amount: 0.5, symbol: "notexistingsymbol", real_bought_for: 500.0, transaction_slot_id: 1}
      iex> ElixirBinanceBot.TransactionMaker.make_sell(transaction)
      {:nok, :transaction_not_done, reason}

  """
  def make_sell(transaction) do
    GenServer.call(__MODULE__, {:make_sell, transaction})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:make_buy, trading_pair, budget, transaction_slot_id}, _from, state) do
    budget =
      budget
      |> NumberFormatter.dynamic_format()

    case post_order(trading_pair, "BUY", "MARKET", quoteOrderQty: budget) do
      {:ok, order} ->
        handle_successful_buy(order, transaction_slot_id)
        {:reply, {:ok, :transaction_done}, state}

      {:error, reason} ->
        Logger.info(%{
          reason: reason,
          trading_pair: trading_pair,
          budget: budget,
          transaction_slot_id: transaction_slot_id
        })

        {:reply, {:nok, :transaction_not_done, reason}, state}
    end
  end

  @impl true
  def handle_call({:make_sell, transaction}, _from, state) do
    quantity = transaction.amount |> NumberFormatter.dynamic_format()

    case post_order(transaction.symbol, "SELL", "MARKET", quantity: quantity) do
      {:ok, order} ->
        handle_successful_sell(order, transaction)
        {:reply, {:ok, :transaction_done}, state}

      {:error, reason} ->
        Logger.info(%{reason: reason, transaction: transaction})
        {:reply, {:nok, :transaction_not_done, reason}, state}
    end
  end

  @doc false
  defp handle_successful_buy(order, transaction_slot_id) do
    {:ok, transaction_data} = prepare_buy_data_for_database(order, transaction_slot_id)

    Transactions.insert_new_transaction(transaction_data)

    TransactionSlots.update_transaction_slot(
      transaction_slot_id,
      %{status: "busy"}
    )

    Logger.info(
      "Bought #{transaction_data.amount} of #{transaction_data.symbol} for #{transaction_data.real_bought_for}. Order: #{inspect(order)}"
    )
  end

  @doc false
  defp prepare_buy_data_for_database(order, transaction_slot_id) do
    symbol = Map.get(order, "symbol")
    buy_price = order["fills"] |> List.first() |> Map.get("price") |> String.to_float()
    sell_price = calculate_sell_price(buy_price)
    real_bought_for = Map.get(order, "cummulativeQuoteQty") |> String.to_float()
    amount = Map.get(order, "executedQty") |> String.to_float()

    transaction_data = %{
      status: "pending",
      transaction_slot_id: transaction_slot_id,
      symbol: symbol,
      buy_price: buy_price,
      sell_price: sell_price,
      amount: amount,
      real_bought_for: real_bought_for
    }

    {:ok, transaction_data}
  end

  @doc false
  defp calculate_sell_price(buy_price) do
    buy_price
    |> Kernel.*(@sell_factor)
    |> NumberFormatter.dynamic_format()
  end

  @doc false
  defp handle_successful_sell(order, transaction) do
    {:ok, transaction_data} = prepare_sell_data_for_database(order, transaction)

    Transactions.update_transaction(
      transaction,
      transaction_data
    )

    TransactionSlots.update_transaction_slot(
      transaction.transaction_slot_id,
      %{budget: transaction_data.real_sold_for, trades_done: +1, status: "ready"}
    )

    Logger.info(
      "Sold #{transaction.amount} of #{transaction.symbol} for #{transaction_data.real_sold_for} with profit: #{transaction_data.profit}. Order: #{inspect(order)}"
    )
  end

  @doc false
  defp prepare_sell_data_for_database(order, transaction) do
    real_sold_for = Map.get(order, "cummulativeQuoteQty") |> String.to_float()
    real_bought_for = Map.get(transaction, :real_bought_for)
    profit = calculate_profit(real_sold_for, real_bought_for)

    transaction_data = %{
      status: "completed",
      real_sold_for: real_sold_for,
      profit: profit
    }

    {:ok, transaction_data}
  end

  @doc false
  defp calculate_profit(sold_for, bought_for) do
    (sold_for - bought_for)
    |> NumberFormatter.dynamic_format()
  end
end

defmodule ElixirBinanceBot.TransactionMaker do
  use GenServer
  require Logger

  alias ElixirBinanceBot.{Transactions, TransactionSlots, NumberFormatter}
  import BinanceApiClient

  @sell_factor 1.015

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def make_buy(trading_pair, budget, transaction_slot_id) do
    GenServer.call(__MODULE__, {:make_buy, trading_pair, budget, transaction_slot_id})
  end

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
        {:ok, transaction_data} = prepare_buy_data_for_database(order, transaction_slot_id)

        Transactions.insert_new_transaction(transaction_data)

        TransactionSlots.update_transaction_slot(
          transaction_slot_id,
          %{status: "busy"}
        )

        Logger.info(
          "Bought #{transaction_data.amount} of #{transaction_data.symbol} for #{transaction_data.real_bought_for}.",
          order: order
        )

        {:reply, {:ok, :transaction_done}, state}

      {:error, reason} ->
        Logger.info(%{reason: reason, trading_pair: trading_pair, budget: budget, transaction_slot_id: transaction_slot_id})
        {:reply, {:nok, :transaction_not_done, reason}, state}
    end
  end

  @impl true
  def handle_call({:make_sell, transaction}, _from, state) do
    quantity = transaction.amount |> NumberFormatter.dynamic_format()

    case post_order(transaction.symbol, "SELL", "MARKET", quantity: quantity) do
      {:ok, order} ->
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
          "Sold #{transaction.amount} of #{transaction.symbol} for #{transaction_data.real_sold_for} with profit: #{transaction_data.profit}.",
          order: order
        )

        {:reply, {:ok, :transaction_done}, state}

      {:error, reason} ->
        Logger.info(%{reason: reason, transaction: transaction})
        {:reply, {:nok, :transaction_not_done, reason}, state}
    end
  end

  defp prepare_buy_data_for_database(order, transaction_slot_id) do
    symbol = Map.get(order, "symbol")
    buy_price = order["fills"] |> List.first() |> Map.get("price") |> String.to_float()
    sell_price = (buy_price * @sell_factor) |> NumberFormatter.dynamic_format()
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

  defp prepare_sell_data_for_database(order, transaction) do
    real_sold_for = Map.get(order, "cummulativeQuoteQty") |> String.to_float()

    profit =
      (real_sold_for - Map.get(transaction, :real_bought_for))
      |> NumberFormatter.dynamic_format()

    transaction_data = %{
      status: "completed",
      real_sold_for: real_sold_for,
      profit: profit
    }

    {:ok, transaction_data}
  end
end

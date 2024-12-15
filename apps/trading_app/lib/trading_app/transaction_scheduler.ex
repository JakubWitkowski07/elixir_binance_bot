defmodule TradingApp.TransactionScheduler do
  @moduledoc """
  Periodically checks trading pairs and manages transactions for buying and selling.

  ## Features

  - Fetches trading pairs and pending transactions.
  - Determines conditions for buying or selling based on current prices.
  - Creates buy or sell transactions and updates transaction slots.
  - Logs errors and transaction activity for better observability.

  ## Usage

  Start the `TransactionScheduler`:

      {:ok, _pid} = TradingApp.TransactionScheduler.start_link()

  This automatically begins periodic checks for transactions based on the configured interval.

  """

  use GenServer
  import Ecto.Query
  require Logger

  alias TradingApp.{
    Repo,
    TradingPairs,
    Transactions,
    TransactionSlots,
    TransactionMaker,
    PriceChecker
  }

  @check_interval :timer.seconds(10)

  @doc """
  Starts the `TransactionScheduler` GenServer.

  ## Examples

      iex> {:ok, pid} = TradingApp.TransactionScheduler.start_link()

  """
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  @doc """
  Initializes the `TransactionScheduler`.

  Sets up the periodic task to check for pending transactions.
  """
  def init(state) do
    schedule_transactions_check()
    {:ok, state}
  end

  @impl true
  @doc """
  Handles scheduled transaction checks.

  This function is triggered periodically to check and process transactions.
  """
  def handle_info(:check_transactions, state) do
    check_pending_transactions()
    schedule_transactions_check()
    {:noreply, state}
  end

  @doc """
  Checks for pending transactions across all trading pairs.

  Iterates through trading pairs, fetches relevant transaction data, and processes them
  based on current market conditions.
  """
  def check_pending_transactions do
    # Retrieve all actual trading pairs
    actual_trading_pairs = TradingPairs.fetch_trading_symbols()

    # Check pending trasactions for all trading_pairs and check terms and conditions of BUY and SELL
    Enum.each(actual_trading_pairs, &process_trading_pair/1)
  end

  @doc false
  defp process_trading_pair(trading_pair) do
    with {:ok, trade_coin} <- fetch_trade_coin(trading_pair),
         {:ok, pending_transactions} <- fetch_pending_for_trading_pair(trading_pair) do
      handle_transactions(trade_coin, trading_pair, pending_transactions)
    else
      {:error, reason} ->
        Logger.info("#{reason}")
        {:error, reason}
    end
  end

  @doc false
  defp fetch_trade_coin(trading_pair) do
    cond do
      String.ends_with?(trading_pair, "BTC") == true -> {:ok, "BTC"}
      String.ends_with?(trading_pair, "FDUSD") == true -> {:ok, "FDUSD"}
      true -> {:error, "#{trading_pair} is not known pair!"}
    end
  end

  @doc false
  defp fetch_pending_for_trading_pair(trading_pair) do
    query =
      from(transaction in Transactions,
        where: transaction.status == "pending" and transaction.symbol == ^trading_pair,
        order_by: transaction.buy_price
      )

    case Repo.all(query) do
      [] -> {:ok, :no_pending_transactions}
      pending_transactions -> {:ok, pending_transactions}
    end
  end

  @doc false
  defp handle_transactions(trade_coin, trading_pair, :no_pending_transactions) do
    case TransactionSlots.fetch_free_transaction_slot(trade_coin) do
      {:ok, free_transaction_slot} ->
        TransactionMaker.make_buy(
          trading_pair,
          free_transaction_slot.budget,
          free_transaction_slot.id
        )
      {:nok, :no_free_transaction_slot} ->
        {:nok, :no_free_transaction_slot}
    end
  end

  @doc false
  defp handle_transactions(trade_coin, trading_pair, pending_transactions) do
    with {:ok, :post_buy_order} <- compare_lowest_and_highest_buy_price(pending_transactions, trading_pair),
         {:ok, free_transaction_slot} <- TransactionSlots.fetch_free_transaction_slot(trade_coin) do

          TransactionMaker.make_buy(
            trading_pair,
            free_transaction_slot.budget,
            free_transaction_slot.id
          )
    else
      {:nok, :do_not_buy} ->
        {:nok, :do_not_buy}

      {:nok, :no_free_transaction_slot} ->
        {:nok, :no_free_transaction_slot}
    end

    Enum.each(pending_transactions, fn pending_transaction ->
      with {:ok, actual_price} <- PriceChecker.fetch_actual_price(trading_pair) do
        if actual_price > pending_transaction.sell_price do
          TransactionMaker.make_sell(pending_transaction)
        end
      else
        {:nok, reason} -> Logger.error("Error fetching price for #{trading_pair}: #{reason}")
      end
    end)
  end

  @doc false
  defp compare_lowest_and_highest_buy_price(pending_transactions, trading_pair) do
    first_record = Enum.at(pending_transactions, 0)
    last_record = Enum.at(pending_transactions, -1)

    next_lower_buy_price = Map.get(first_record, :buy_price) * 0.985
    next_higher_buy_price = Map.get(last_record, :buy_price) * 1.015

    case PriceChecker.fetch_actual_price(trading_pair) do
      {:ok, actual_price} ->
        cond do
          actual_price <= next_lower_buy_price -> {:ok, :post_buy_order}
          actual_price >= next_higher_buy_price -> {:ok, :post_buy_order}
          true -> {:nok, :do_not_buy}
        end

      {:nok, reason} ->
        Logger.info(%{reason: reason, pricechecking: :prichecking})
        {:nok, :do_not_buy}
    end
  end

  @doc false
  defp schedule_transactions_check() do
    Process.send_after(self(), :check_transactions, @check_interval)
  end
end

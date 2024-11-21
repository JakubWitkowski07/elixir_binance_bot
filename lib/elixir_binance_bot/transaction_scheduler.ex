defmodule ElixirBinanceBot.TransactionScheduler do
  use GenServer
  import Ecto.Query
  require Logger

  alias ElixirBinanceBot.{
    Repo,
    TradingPairs,
    Transactions,
    TransactionSlots,
    TransactionMaker,
    PriceChecker
  }

  @check_interval :timer.seconds(60)

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    schedule_transactions_check()
    {:ok, state}
  end

  @impl true
  def handle_info(:check_transactions, state) do
    check_pending_transactions()
    schedule_transactions_check()
    {:noreply, state}
  end

  def check_pending_transactions do
    # Retrieve all actual trading pairs
    actual_trading_pairs = TradingPairs.fetch_trading_symbols()

    # Check pending trasactions for all trading_pairs and check terms and conditions of BUY
    for trading_pair <- actual_trading_pairs do
      case fetch_trade_coin(trading_pair) do
        {:ok, trade_coin} ->
          case TransactionSlots.fetch_free_transaction_slot(trade_coin) do
            {:ok, free_transaction_slot} ->
              case fetch_pending_for_trading_pair(trading_pair) do
                {:ok, :no_pending_transactions} ->
                  TransactionMaker.make_buy(
                    trading_pair,
                    free_transaction_slot.budget,
                    free_transaction_slot.id
                  )

                {:ok, pending_transactions} ->
                  case compare_lowest_and_highest_buy_price(pending_transactions, trading_pair) do
                    {:ok, :post_buy_order} ->
                      TransactionMaker.make_buy(
                        trading_pair,
                        free_transaction_slot.budget,
                        free_transaction_slot.id
                      )

                    {:nok, :do_not_buy} ->
                      nil
                  end

                  for pending_transaction <- pending_transactions do
                    {:ok, actual_price} = BinanceApiClient.check_price(trading_pair)

                    cond do
                      actual_price > pending_transaction.sell_price ->
                        TransactionMaker.make_sell(pending_transaction)

                      true ->
                        nil
                    end
                  end
              end

            {:nok, :no_free_transaction_slot} ->
              {:nok, :no_free_transaction_slot}
          end

        {:nok, :not_known_trade_coin} ->
          {:nok, "Not known trade coin - check trading pairs table!"}
      end
    end
  end

  defp fetch_trade_coin(trading_pair) do
    cond do
      String.ends_with?(trading_pair, "BTC") == true -> {:ok, "BTC"}
      String.ends_with?(trading_pair, "FDUSD") == true -> {:ok, "FDUSD"}
      true -> {:nok, :not_known_trade_coin}
    end
  end

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

  defp schedule_transactions_check() do
    Process.send_after(self(), :check_transactions, @check_interval)
  end
end

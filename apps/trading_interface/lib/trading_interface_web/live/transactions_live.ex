defmodule TradingInterfaceWeb.TransactionsLive do
require Logger
  use TradingInterfaceWeb, :live_view

  alias TradingApp.Transactions

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TradingInterface.PubSub, "transactions")
      Phoenix.PubSub.subscribe(TradingInterface.PubSub, "price_updates")
    end

    {:ok,
      socket
      |> assign(:transactions, fetch_transactions())
      |> assign(:prices, %{}) # Initialize prices map
    }
  end

  def handle_info(%{"data" => _data, "id" => _id, "table" => "transactions", "type" => _type}, socket) do
    {:noreply, assign(socket, :transactions, fetch_transactions())}
  end

  def handle_info(prices_table, socket) when is_map(prices_table) do
    # Assume prices_table is the map broadcasted via "price_updates" topic
    {:noreply, assign(socket, :prices, prices_table)}
  end

  def handle_info(msg, socket) do
    Logger.warning("Unexpected message received: #{inspect(msg)}")
    {:noreply, socket}
  end

  defp fetch_transactions do
    Transactions.get_pending_transactions()
  end

  defp calculate_profit(nil, _buy_price, _amount), do: "N/A" # No price available
  defp calculate_profit(current_price, buy_price, amount) do
    profit = (current_price - buy_price) * amount
    TradingApp.NumberFormatter.dynamic_format(profit)
  end

  defp fetch_trade_coin(trading_pair) do
    cond do
      String.ends_with?(trading_pair, "BTC") == true -> "BTC"
      String.ends_with?(trading_pair, "FDUSD") == true -> "FDUSD"
      true -> {:error, "#{trading_pair} is not known pair!"}
    end
  end
end

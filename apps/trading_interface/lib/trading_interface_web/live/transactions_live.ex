defmodule TradingInterfaceWeb.TransactionsLive do
require Logger
  use TradingInterfaceWeb, :live_view

  alias TradingApp.Transactions

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TradingInterface.PubSub, "transactions")
    end
    {:ok, assign(socket, :transactions, fetch_transactions())}
  end

  def handle_info(%{"data" => _data, "id" => _id, "table" => "transactions", "type" => _type}, socket) do
    {:noreply, assign(socket, :transactions, fetch_transactions())}
  end

  def handle_info(msg, socket) do
    Logger.warning("Unexpected message received: #{inspect(msg)}")
    {:noreply, socket}
  end

  defp fetch_transactions do
    Transactions.get_pending_transactions()
  end
end

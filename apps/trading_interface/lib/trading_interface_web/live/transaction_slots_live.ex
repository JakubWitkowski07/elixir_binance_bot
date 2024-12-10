defmodule TradingInterfaceWeb.TransactionSlotsLive do
  use TradingInterfaceWeb, :live_view

  alias TradingApp.TransactionSlots
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TradingInterface.PubSub, "transaction_slots")
    end

    {:ok,
      socket
      |> assign(:transaction_slots, fetch_transaction_slots())
    }
  end

  @impl true
  def handle_info(%{"table" => "transaction_slots", "type" => _type}, socket) do
    {:noreply, assign(socket, :transaction_slots, fetch_transaction_slots())}
  end

  @impl true
  def handle_info(msg, socket) do
    Logger.warning("Unexpected message received: #{inspect(msg)}")
    {:noreply, socket}
  end

  defp fetch_transaction_slots do
    TransactionSlots.fetch_all_transaction_slots()
  end
end

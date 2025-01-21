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
     |> assign(:show_modal, false)
     |> assign(:transaction_slot_params, %{"trade_coin" => nil, "budget" => nil})}
  end

  @impl true
  def handle_event("toggle_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, !socket.assigns.show_modal)}
  end

  @impl true
  def handle_event(
        "create_transaction_slot",
        %{"trade_coin" => trade_coin, "budget" => budget},
        socket
      ) do
    case TransactionSlots.create_new_transaction_slot(budget, trade_coin) do
      {:ok, _transaction_slot} ->
        {:noreply,
         socket
         |> assign(:transaction_slots, fetch_transaction_slots())
         |> assign(:show_modal, false)
         |> put_flash(:info, "Transaction slot created successfully.")}

      {:error, msg} ->
        {:noreply,
         socket
         |> assign(:transaction_slots, fetch_transaction_slots())
         |> assign(:show_modal, false)
         |> put_flash(:error, "Failed to create transaction slot. #{msg}.")}
    end
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

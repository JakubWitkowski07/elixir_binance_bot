defmodule TradingInterfaceWeb.TradingPairsLive do
  use TradingInterfaceWeb, :live_view

  alias TradingApp.TradingPairs
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(TradingInterface.PubSub, "trading_pairs")
    end

    {:ok,
     socket
     |> assign(:trading_pairs, fetch_trading_pairs())
     |> assign(:show_modal, false)
     |> assign(:trading_pair_params, %{"trading_pair" => nil})}
  end

  @impl true
  def handle_event("toggle_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, !socket.assigns.show_modal)}
  end

  @impl true
  def handle_event("add_new_trading_pair", %{"trading_pair" => trading_pair}, socket) do
    case TradingPairs.insert_trading_pair(trading_pair) do
      {:ok, _trading_pair} ->
        {:noreply,
         socket
         |> assign(:trading_pairs, fetch_trading_pairs())
         |> assign(:show_modal, false)
         |> put_flash(:info, "Trading pair added successfully.")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:trading_pairs, fetch_trading_pairs())
         |> assign(:show_modal, false)
         |> put_flash(:error, "Failed to add trading pair.")}
    end
  end

  @impl true
  def handle_info(%{"table" => "trading_pairs"}, socket) do
    {:noreply, assign(socket, :trading_pairs, fetch_trading_pairs())}
  end

  @impl true
  def handle_info(msg, socket) do
    Logger.warning("Unexpected message received: #{inspect(msg)}")
    {:noreply, socket}
  end

  def fetch_trading_pairs do
    TradingPairs.fetch_trading_symbols()
  end
end

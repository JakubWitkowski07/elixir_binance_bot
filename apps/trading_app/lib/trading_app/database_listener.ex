defmodule TradingApp.DatabaseListener do
  alias Phoenix.PubSub
  use GenServer

  @transactions_channel "transactions_changes"
  @trading_pairs_channel "trading_pairs_changes"
  @transaction_slots_channel "transaction_slots_changes"

  defstruct [:pid, :transactions_ref, :trading_pairs_ref, :transaction_slots_ref]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, pid} = Postgrex.Notifications.start_link(TradingApp.Repo.config())
    {:ok, transactions_ref} = Postgrex.Notifications.listen(pid, @transactions_channel)
    {:ok, trading_pairs_ref} = Postgrex.Notifications.listen(pid, @trading_pairs_channel)
    {:ok, transaction_slots_ref} = Postgrex.Notifications.listen(pid, @transaction_slots_channel)

    {:ok,
     %__MODULE__{
       pid: pid,
       transactions_ref: transactions_ref,
       trading_pairs_ref: trading_pairs_ref,
       transaction_slots_ref: transaction_slots_ref
     }}
  end

  def handle_info(
        {:notification, pid, transactions_ref, @transactions_channel, payload},
        %{pid: pid, transactions_ref: transactions_ref, trading_pairs_ref: _trading_pairs_ref} =
          state
      ) do
    change = Jason.decode!(payload)
    PubSub.broadcast(TradingInterface.PubSub, "transactions", change)
    {:noreply, state}
  end

  def handle_info(
        {:notification, pid, trading_pairs_ref, @trading_pairs_channel, payload},
        %{pid: pid, transactions_ref: _transactions_ref, trading_pairs_ref: trading_pairs_ref} =
          state
      ) do
    TradingApp.PriceChecker.update_state()
    {:noreply, state}
  end

  def handle_info(
        {:notification, pid, transaction_slots_ref, @transaction_slots_channel, payload},
        %{pid: pid, transactions_ref: _transactions_ref, trading_pairs_ref: _trading_pairs_ref, transaction_slots_ref: transaction_slots_ref} =
          state
      ) do
    change = Jason.decode!(payload)
    PubSub.broadcast(TradingInterface.PubSub, "transaction_slots", change)
    {:noreply, state}
  end
end

defmodule TradingApp.DatabaseListener do
  @moduledoc """
  A GenServer that listens for changes in the database and broadcasts updates via Phoenix PubSub.

  This module subscribes to PostgreSQL notification channels to monitor changes in key database tables:
  - Transactions
  - Trading Pairs
  - Transaction Slots

  When changes are detected, they are broadcasted to relevant Phoenix PubSub topics or used to trigger updates within the application.

  ## Notification Channels
  - `transactions_changes`: Broadcasts changes to the `"transactions"` topic when new transaction appears or existing transaction is updated.
  - `trading_pairs_changes`: Triggers updates to the application's state for fetching changes in trading pairs list.
  - `transaction_slots_changes`: Broadcasts changes to the `"transaction_slots"` topic when new transaction slot appears or existing transaction slot is updated.

  ## Dependencies
  - This module requires `Phoenix.PubSub` for broadcasting updates.
  - PostgreSQL must be configured to send notifications for the corresponding tables.
  """
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

  # Handles notifications for changes in the `transactions` table.
  def handle_info(
        {:notification, pid, transactions_ref, @transactions_channel, payload},
        %{pid: pid, transactions_ref: transactions_ref, trading_pairs_ref: _trading_pairs_ref} =
          state
      ) do
    change = Jason.decode!(payload)
    PubSub.broadcast(TradingInterface.PubSub, "transactions", change)
    {:noreply, state}
  end

  # Handles notifications for changes in the `trading_pairs` table.
  def handle_info(
        {:notification, pid, trading_pairs_ref, @trading_pairs_channel, _payload},
        %{pid: pid, transactions_ref: _transactions_ref, trading_pairs_ref: trading_pairs_ref} =
          state
      ) do
    TradingApp.PriceChecker.update_state()
    {:noreply, state}
  end

  # Handles notifications for changes in the `transaction_slots` table.
  def handle_info(
        {:notification, pid, transaction_slots_ref, @transaction_slots_channel, payload},
        %{
          pid: pid,
          transactions_ref: _transactions_ref,
          trading_pairs_ref: _trading_pairs_ref,
          transaction_slots_ref: transaction_slots_ref
        } =
          state
      ) do
    change = Jason.decode!(payload)
    PubSub.broadcast(TradingInterface.PubSub, "transaction_slots", change)
    {:noreply, state}
  end
end

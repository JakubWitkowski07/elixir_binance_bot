defmodule TradingApp.TransactionSlots do
  @moduledoc """
  Handles operations related to transaction slots for trading.

  Transaction slots are used to allocate budgets, track the number of trades,
  and manage the status of transaction slots. This module includes functionality
  for creating, updating, retrieving, and validating transaction slots.

  ## Schema Fields

    - `:trade_coin` - The trade coin associated with the slot (e.g., "BTC").
    - `:budget` - The allocated budget for the transaction slot.
    - `:trades_done` - The number of trades completed in this slot.
    - `:status` - The status of the transaction slot (`"ready"`, `"busy"`, or `"blocked"`).
    - Timestamps (`:inserted_at` and `:updated_at`).

  ## Example Usage

      iex> attrs = %{trade_coin: "BTC", budget: 100.0, trades_done: 0, status: "ready"}
      iex> changeset = TradingApp.TransactionSlots.create_changeset(%TransactionSlots{}, attrs)
      iex> Repo.insert(changeset)

      iex> TradingApp.TransactionSlots.create_new_transaction_slot(50.0, "ETH")
      {:ok, %TransactionSlots{}}

      iex> TradingApp.TransactionSlots.fetch_free_transaction_slot("BTC")
      {:ok, %TransactionSlots{}}
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  require Logger
  alias TradingApp.Repo
  alias __MODULE__

  @primary_key {:id, :id, autogenerate: true}
  schema "transaction_slots" do
    field(:trade_coin, :string)
    field(:budget, :float)
    field(:trades_done, :integer)
    field(:status, :string)
    timestamps()
  end

  @doc """
  Creates a changeset for a new transaction slot.

  ## Parameters

    - `transaction_slot` - An empty `%TransactionSlots{}` struct.
    - `attrs` - A map containing attributes for the transaction slot.

  """
  def create_changeset(transaction_slot, attrs) do
    transaction_slot
    |> cast(attrs, [
      :trade_coin,
      :budget,
      :trades_done,
      :status
    ])
    |> validate_required([
      :trade_coin,
      :budget,
      :trades_done,
      :status
    ])
    |> validate_inclusion(:status, ["ready"])
  end

  @doc """
  Creates a changeset for updating a transaction slot.

  ## Parameters

    - `transaction_slot` - An existing `%TransactionSlots{}` struct.
    - `attrs` - A map containing updated attributes for the transaction slot.

  ## Examples

      iex> attrs = %{budget: 50.0, trades_done: 1, status: "busy"}
      iex> TradingApp.TransactionSlots.update_changeset(transaction_slot, attrs)
      #Ecto.Changeset<...>
  """
  def update_changeset(transaction_slot, attrs) do
    transaction_slot
    |> cast(attrs, [
      :budget,
      :trades_done,
      :status
    ])
    |> validate_required([
      :budget,
      :trades_done,
      :status
    ])
    |> validate_inclusion(:status, ["ready", "busy", "blocked"])
  end

  @doc """
  Creates a new transaction slot with the given budget and trade coin.

  ## Parameters

    - `budget` - The budget allocated for the transaction slot.
    - `trade_coin` - The trade coin associated with the transaction slot.

  ## Returns

    - `{:ok, %TransactionSlots{}}` on success.
    - `{:error, %Ecto.Changeset{}}` on failure.

  ## Examples

      iex> TradingApp.TransactionSlots.create_new_transaction_slot(100.0, "BTC")
      {:ok, %TransactionSlots{}}
  """
  def create_new_transaction_slot(budget, trade_coin) do
    attrs = %{trade_coin: trade_coin, budget: budget, trades_done: 0, status: "ready"}

    %TransactionSlots{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing transaction slot with new data.

  ## Parameters

    - `id` - The ID of the transaction slot to update.
    - `slot_data` - A map containing updated attributes.

  ## Returns

    - `{:ok, %TransactionSlots{}}` on success.
    - `{:error, %Ecto.Changeset{}}` on failure.

  ## Examples

      iex> TradingApp.TransactionSlots.update_transaction_slot(1, %{budget: 7.77, trades_done: +1, status: "ready"})
      {:ok, %TransactionSlots{}}

      iex> TradingApp.TransactionSlots.update_transaction_slot(2, %{status: "busy"})
      {:ok, %TransactionSlots{}}
  """
  def update_transaction_slot(id, slot_data) do
    transaction = Repo.get!(TransactionSlots, id)

    transaction
    |> update_changeset(slot_data)
    |> Repo.update()
  end

  @doc """
  Fetches the first free transaction slot for a given trade coin.

  A free transaction slot is one with the `"ready"` status. If no free slots are available,
  it returns an error.

  ## Parameters

    - `trade_coin` - The trade coin to filter transaction slots by.

  ## Returns

    - `{:ok, %TransactionSlots{}}` on success.
    - `{:nok, :no_free_transaction_slot}` if no slots are available.
    - `{:error, String.t()}` if the slot's budget is 0 and it is blocked.

  ## Examples

      iex> TradingApp.TransactionSlots.fetch_free_transaction_slot("BTC")
      {:ok, %TransactionSlots{}}

      iex> TradingApp.TransactionSlots.fetch_free_transaction_slot("FDUSD")
      {:nok, :no_free_transaction_slot}
  """
  def fetch_free_transaction_slot(trade_coin) do
    query =
      from(transaction_slot in TransactionSlots,
        where: transaction_slot.trade_coin == ^trade_coin and transaction_slot.status == "ready",
        order_by: [asc: transaction_slot.budget],
        limit: 1
      )

    case Repo.one(query) do
      nil ->
        {:nok, :no_free_transaction_slot}

      free_transaction_slot ->
        cond do
          free_transaction_slot.budget == 0.0 ->
            update_transaction_slot(free_transaction_slot.id, %{
              budget: free_transaction_slot.budget,
              trades_done: +0,
              status: "blocked"
            })

            Logger.error("Transaction slot id: #{free_transaction_slot.id} blocked!")
            {:error, "Transaction slot id: #{free_transaction_slot.id} blocked!"}

          true ->
            {:ok, free_transaction_slot}
        end
    end
  end

  @doc """
  Fetches all transaction slots from the database.

  ## Returns

    - A list of `%TransactionSlots{}` structs sorted by their ID.

  ## Examples

      iex> TradingApp.TransactionSlots.fetch_all_transaction_slots()
      [%TransactionSlots{}, %TransactionSlots{}]
  """
  def fetch_all_transaction_slots do
    query =
      from(transaction_slot in TransactionSlots,
        select: transaction_slot,
        order_by: [asc: transaction_slot.id]
      )

    Repo.all(query)
  end
end

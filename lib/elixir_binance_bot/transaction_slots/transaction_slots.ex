defmodule ElixirBinanceBot.TransactionSlots do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias ElixirBinanceBot.Repo
  alias __MODULE__

  @primary_key {:id, :id, autogenerate: true}
  schema "transaction_slots" do
    field(:trade_coin, :string)
    field(:budget, :float)
    field(:trades_done, :integer)
    field(:status, :string)
    timestamps()
  end

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
    |> validate_inclusion(:status, ["ready", "busy"])
  end

  def create_new_transaction_slot(budget, trade_coin) do
    attrs = %{trade_coin: trade_coin, budget: budget, trades_done: 0, status: "ready"}

    %TransactionSlots{}
    |> create_changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction_slot(id, slot_data) do
    transaction = Repo.get!(TransactionSlots, id)

    transaction
    |> update_changeset(slot_data)
    |> Repo.update()
  end

  def fetch_free_transaction_slot(trade_coin) do
    query =
      from(transaction_slot in TransactionSlots,
        where: transaction_slot.trade_coin == ^trade_coin and transaction_slot.status == "ready",
        order_by: [asc: transaction_slot.budget],
        limit: 1
      )

    case Repo.one(query) do
      nil -> {:nok, :no_free_transaction_slot}
      free_transaction_slot -> {:ok, free_transaction_slot}
    end
  end
end

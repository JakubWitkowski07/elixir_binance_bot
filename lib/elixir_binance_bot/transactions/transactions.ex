defmodule ElixirBinanceBot.Transactions do
  use Ecto.Schema
  import Ecto.Changeset
  alias ElixirBinanceBot.Repo
  alias __MODULE__

  @primary_key {:id, :id, autogenerate: true}
  schema "transactions" do
    field(:status, :string)
    field(:transaction_slot_id, :integer)
    field(:symbol, :string)
    field(:buy_price, :float)
    field(:sell_price, :float)
    field(:amount, :float)
    field(:real_bought_for, :float)
    field(:real_sold_for, :float)
    field(:buy_fee, :float)
    field(:sell_fee, :float)
    field(:profit, :float)
    timestamps()
  end

  def create_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :status,
      :transaction_slot_id,
      :symbol,
      :buy_price,
      :sell_price,
      :amount,
      :real_bought_for
    ])
    |> validate_required([
      :status,
      :transaction_slot_id,
      :symbol,
      :buy_price,
      :sell_price,
      :amount,
      :real_bought_for
    ])
    |> validate_inclusion(:status, ["pending"])
  end

  def update_changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :status,
      :real_sold_for,
      :profit
    ])
    |> validate_required([
      :status,
      :real_sold_for,
      :profit
    ])
    |> validate_inclusion(:status, ["completed"])
  end

  # Insert new transaction (after buy)
  def insert_new_transaction(transaction_data) do
    %Transactions{}
    |> create_changeset(transaction_data)
    |> Repo.insert()
  end

  # Update existing transaction (after sell)
  def update_transaction(%Transactions{} = transaction, transaction_data) do
    transaction
    |> update_changeset(transaction_data)
    |> Repo.update()
  end
end

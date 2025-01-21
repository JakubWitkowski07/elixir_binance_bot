defmodule TradingApp.Transactions do
  @moduledoc """
  Manages operations related to trading transactions.

  This module handles the creation, updating, and retrieval of transactions
  within the trading application. Each transaction represents a trading operation
  and contains details such as prices, fees, and status.

  ## Schema Fields

    - `:status` - The current status of the transaction (`"pending"` or `"completed"`).
    - `:transaction_slot_id` - The ID of the associated transaction slot.
    - `:symbol` - The trading pair symbol (e.g., "BTCUSDT").
    - `:buy_price` - The price at which the asset was bought.
    - `:sell_price` - The price at which the asset was sold.
    - `:amount` - The quantity of the asset traded.
    - `:real_bought_for` - The total cost of the asset including fees.
    - `:real_sold_for` - The total revenue from selling the asset.
    - `:buy_fee` - The fee incurred during the buying process.
    - `:sell_fee` - The fee incurred during the selling process.
    - `:profit` - The profit or loss from the transaction.
    - Timestamps (`:inserted_at` and `:updated_at`).
  """
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias TradingApp.Repo
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

  @doc """
  Creates a changeset for a new transaction.

  ## Parameters

    - `transaction` - An empty or existing `%Transactions{}` struct.
    - `attrs` - A map of attributes for the new transaction.
  """
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

  @doc """
  Creates a changeset for updating an existing transaction.

  ## Parameters

    - `transaction` - An existing `%Transactions{}` struct.
    - `attrs` - A map of updated attributes for the transaction.
  """
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

  @doc """
  Inserts a new transaction into the database. The function is called every time when a new transaction is created during the buying process.

  ## Parameters

    - `transaction_data` - A map of attributes for the new transaction.

  ## Returns

    - `{:ok, %Transactions{}}` on success.
    - `{:error, %Ecto.Changeset{}}` on failure.

  ## Examples

      iex> attrs = %{status: "pending", transaction_slot_id: 1, symbol: "BTCUSDT", buy_price: 25000, sell_price: 27000, amount: 0.1, real_bought_for: 2500}
      iex> TradingApp.Transactions.insert_new_transaction(attrs)
      {:ok, %Transactions{}}
  """
  def insert_new_transaction(transaction_data) do
    %Transactions{}
    |> create_changeset(transaction_data)
    |> Repo.insert()
  end

  @doc """
  Updates an existing transaction with new data. Function is called every time after selling process.

  ## Parameters

    - `transaction` - The `%Transactions{}` struct to update.
    - `transaction_data` - A map of updated attributes.

  ## Returns

    - `{:ok, %Transactions{}}` on success.
    - `{:error, %Ecto.Changeset{}}` on failure.

  ## Examples

      iex> transaction = Repo.get!(TradingApp.Transactions, 1)
      iex> attrs = %{status: "completed", real_sold_for: 2700, profit: 200}
      iex> TradingApp.Transactions.update_transaction(transaction, attrs)
      {:ok, %Transactions{}}
  """
  def update_transaction(%Transactions{} = transaction, transaction_data) do
    transaction
    |> update_changeset(transaction_data)
    |> Repo.update()
  end

  @doc """
  Retrieves all transactions with the status `"pending"`.

  ## Returns

    - A list of `%Transactions{}` structs.

  ## Examples

      iex> TradingApp.Transactions.get_pending_transactions()
      [%Transactions{}, %Transactions{}]
  """
  def get_pending_transactions do
    query =
      from(transaction in Transactions,
        where: transaction.status == "pending"
      )

    Repo.all(query)
  end
end

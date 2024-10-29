defmodule ElixirBinanceBot.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :integer, primary_key: true
      add :status, :string
      add :transaction_slot_id, :integer
      add :symbol, :string
      add :buy_price, :float
      add :sell_price, :float
      add :amount, :float
      add :real_bought_for, :float
      add :real_sold_for, :float
      add :buy_fee, :float
      add :sell_fee, :float
      add :profit, :float
    end
  end
end

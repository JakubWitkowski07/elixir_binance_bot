defmodule ElixirBinanceBot.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
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
      timestamps()
    end
  end
end

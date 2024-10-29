defmodule ElixirBinanceBot.Repo.Migrations.CreateTransactionSlots do
  use Ecto.Migration

  def change do
    create table(:transaction_slots, primary_key: false) do
      add :id, :integer, primary_key: true
      add :budget, :float
      add :trades_done, :integer
      add :trade_coin, :string
      add :busy, :boolean
    end
  end
end

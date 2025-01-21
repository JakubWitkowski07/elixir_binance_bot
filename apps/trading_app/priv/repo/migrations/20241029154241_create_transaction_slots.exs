defmodule ElixirBinanceBot.Repo.Migrations.CreateTransactionSlots do
  use Ecto.Migration

  def change do
    create table(:transaction_slots) do
      add :trade_coin, :string
      add :budget, :float
      add :trades_done, :integer
      add :status, :string
      timestamps()
    end
  end
end

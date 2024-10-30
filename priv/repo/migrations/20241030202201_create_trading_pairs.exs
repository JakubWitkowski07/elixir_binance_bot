defmodule ElixirBinanceBot.Repo.Migrations.CreateTradingPairs do
  use Ecto.Migration

  def change do
    create table(:trading_pairs) do
      add :symbol, :string
      add :last_price, :float
      timestamps()
    end
  end
end

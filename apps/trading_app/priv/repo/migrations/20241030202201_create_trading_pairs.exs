defmodule ElixirBinanceBot.Repo.Migrations.CreateTradingPairs do
  use Ecto.Migration

  def change do
    create table(:trading_pairs) do
      add :symbol, :string
      add :last_price, :float
      timestamps()
    end

    # Add a unique index on the :symbol column
    create unique_index(:trading_pairs, [:symbol])
  end
end

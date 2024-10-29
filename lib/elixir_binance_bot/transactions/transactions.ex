defmodule ElixirBinanceBot.Transactions.Transaction do
  use Ecto.Schema

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
  end
end

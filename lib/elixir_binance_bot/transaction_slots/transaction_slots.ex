defmodule ElixirBinanceBot.TransactionSlots.TransactionSlot do
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: true}
  schema "transaction_slots" do
    field(:budget, :float)
    field(:trades_done, :integer)
    field(:trade_coin, :string)
    field(:busy, :boolean)
  end
end

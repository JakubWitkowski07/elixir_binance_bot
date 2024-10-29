defmodule ElixirBinanceBot.Repo do
  use Ecto.Repo,
    otp_app: :elixir_binance_bot,
    adapter: Ecto.Adapters.Postgres
end

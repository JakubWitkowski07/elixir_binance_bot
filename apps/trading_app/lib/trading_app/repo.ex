defmodule TradingApp.Repo do
  use Ecto.Repo,
    otp_app: :trading_app,
    adapter: Ecto.Adapters.Postgres
end

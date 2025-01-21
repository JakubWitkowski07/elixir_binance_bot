defmodule TradingInterface.Repo do
  use Ecto.Repo,
    otp_app: :trading_interface,
    adapter: Ecto.Adapters.Postgres
end

defmodule TradingApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Ensure the Repo is started
      TradingApp.Repo,
      TradingApp.PriceChecker,
      TradingApp.TransactionMaker,
      TradingApp.TransactionScheduler,
      TradingApp.DatabaseListener
    ]

    opts = [strategy: :one_for_one, name: TradingApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

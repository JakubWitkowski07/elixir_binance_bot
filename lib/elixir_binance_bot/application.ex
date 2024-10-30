defmodule ElixirBinanceBot.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Ensure the Repo is started
      ElixirBinanceBot.Repo,
      ElixirBinanceBot.PriceChecker
    ]

    opts = [strategy: :one_for_one, name: ElixirBinanceBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

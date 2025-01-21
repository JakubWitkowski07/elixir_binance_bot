defmodule TradingInterface.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TradingInterfaceWeb.Telemetry,
      TradingInterface.Repo,
      {DNSCluster, query: Application.get_env(:trading_interface, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: TradingInterface.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: TradingInterface.Finch},
      # Start a worker by calling: TradingInterface.Worker.start_link(arg)
      # {TradingInterface.Worker, arg},
      # Start to serve requests, typically the last entry
      TradingInterfaceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingInterface.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TradingInterfaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

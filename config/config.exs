import Config

config :elixir_binance_bot, ecto_repos: [ElixirBinanceBot.Repo]

config :elixir_binance_bot, ElixirBinanceBot,
  # MAIN NET
  # base_url: "https://api.binance.com"
  # TEST NET
  base_url: "https://testnet.binance.vision"

# Import secret config to get access to API keys and database credentials
import_config "secret.exs"

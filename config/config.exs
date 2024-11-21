import Config

config :elixir_binance_bot, ecto_repos: [ElixirBinanceBot.Repo]

config :elixir_binance_bot, ElixirBinanceBot,
  # MAIN NET
  # base_url: "https://api.binance.com"
  # TEST NET
  base_url: "https://testnet.binance.vision"

# Import secret config to get access to API keys and database credentials
import_config "secret.exs"

config :logger, level: :info

config :logger, :default_handler,
  config: [
    file: ~c"system.log",
    filesync_repeat_interval: 5000,
    file_check: 5000,
    max_no_bytes: 10_000_000,
    max_no_files: 5,
    compress_on_rotate: true
  ]

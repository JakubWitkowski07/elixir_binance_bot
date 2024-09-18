import Config

config :elixir_binance_bot, BinanceTradingBot,
  base_url: "https://api.binance.com"

# Import secret config to get access to API keys
import_config "secret.exs"

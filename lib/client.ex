defmodule BinanceTradingBot.Client do
  @base_url Application.compile_env(:elixir_binance_bot, BinanceTradingBot)[:base_url]
  @api_key Application.compile_env(:elixir_binance_bot, BinanceTradingBot)[:api_key]
  @api_secret Application.compile_env(:elixir_binance_bot, BinanceTradingBot)[:api_secret]

  def get_account_info do
    timestamp = :os.system_time(:millisecond)
    query_string = "timestamp=#{timestamp}"
    signature = generate_signature(query_string)

    url = "#{@base_url}/api/v3/account?#{query_string}&signature=#{signature}"
    headers = [{"X-MBX-APIKEY", @api_key}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, "Request failed with status code #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp generate_signature(query_string) do
    :crypto.mac(:hmac, :sha256, @api_secret, query_string)
    |> Base.encode16(case: :lower)
  end
end

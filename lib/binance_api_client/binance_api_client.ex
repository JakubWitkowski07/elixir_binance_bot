defmodule BinanceApiClient do
  @base_url Application.compile_env(:elixir_binance_bot, ElixirBinanceBot)[:base_url]
  @api_key Application.compile_env(:elixir_binance_bot, ElixirBinanceBot)[:api_key]
  @api_secret Application.compile_env(:elixir_binance_bot, ElixirBinanceBot)[:api_secret]

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

  def check_price(symbol) do
    url = "#{@base_url}/api/v3/ticker/price?symbol=#{symbol}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"price" => price}} ->
            {:ok, String.to_float(price)}

          {:error, _error} ->
            {:error, "Failed to parse response"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        {:error, "Error: #{status_code} - #{body}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Request failed: #{inspect(reason)}"}
    end
  end

  def post_order(symbol, side, type, opts \\ []) do
    # Get Binance server time
    case get_binance_server_time() do
      {:ok, server_time} ->
        # Build the base query string
        query_params = [
          {"symbol", symbol},
          {"side", side},
          {"type", type},
          {"timestamp", server_time}
        ]

        # Add optional parameters if they are provided in `opts`
        query_params =
          query_params ++
            Enum.reduce(opts, [], fn
              {:timeInForce, value}, acc -> [{"timeInForce", value} | acc]
              {:quantity, value}, acc -> [{"quantity", value} | acc]
              {:quoteOrderQty, value}, acc -> [{"quoteOrderQty", value} | acc]
              {:price, value}, acc -> [{"price", value} | acc]
              {:newClientOrderId, value}, acc -> [{"newClientOrderId", value} | acc]
              {:strategyId, value}, acc -> [{"strategyId", value} | acc]
              {:strategyType, value}, acc -> [{"strategyType", value} | acc]
              {:stopPrice, value}, acc -> [{"stopPrice", value} | acc]
              {:icebergQty, value}, acc -> [{"icebergQty", value} | acc]
              {:newOrderRespType, value}, acc -> [{"newOrderRespType", value} | acc]
              {:recvWindow, value}, acc -> [{"recvWindow", value} | acc]
              _, acc -> acc
            end)

        # Generate query string from the parameters
        query_string = URI.encode_query(query_params)

        # Generate the signature
        signature = generate_signature(query_string)

        # Combine the query string and the signature
        full_query_string = query_string <> "&signature=#{signature}"

        # Define the request URL
        url = "#{@base_url}/api/v3/order"

        # Set the headers with the API key
        headers = [
          {"X-MBX-APIKEY", @api_key}
          # {"Content-Type", "application/x-www-form-urlencoded"}
        ]

        # Make the HTTP POST request to place the order
        case HTTPoison.post(url, full_query_string, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            {:ok, Jason.decode!(body)}

          {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
            {:error, "Request failed with status code #{status_code}. Body: #{body}"}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, "HTTP request failed: #{reason}"}
        end

      {:error, reason} ->
        {:error, "Failed to fetch Binance server time: #{reason}"}
    end
  end

  defp generate_signature(query_string) do
    :crypto.mac(:hmac, :sha256, @api_secret, query_string)
    |> Base.encode16(case: :lower)
  end

  defp get_binance_server_time do
    url = "#{@base_url}/api/v3/time"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)["serverTime"]}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end

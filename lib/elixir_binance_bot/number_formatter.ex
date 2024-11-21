defmodule ElixirBinanceBot.NumberFormatter do
  def dynamic_format(value) when is_float(value) do
    # Determine precision
    precision =
      cond do
        abs(value) >= 1 -> 2
        abs(value) >= 0.01 -> 4
        abs(value) >= 0.0001 -> 6
        true -> 8
      end

    # Convert to string with precision
    :erlang.float_to_binary(value, decimals: precision)
  end
end

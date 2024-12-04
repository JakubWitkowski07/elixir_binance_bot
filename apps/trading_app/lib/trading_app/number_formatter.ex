defmodule TradingApp.NumberFormatter do
  @moduledoc """
  A utility module for formatting floating-point numbers based on their magnitude.
  """

  @doc """
  Dynamically formats a floating-point number based on its magnitude.

  The number of decimal places is determined as follows:
  - 2 decimals for numbers >= 1
  - 4 decimals for numbers >= 0.01 and < 1
  - 6 decimals for numbers >= 0.0001 and < 0.01
  - 8 decimals for numbers < 0.0001

  ## Parameters

  - `value` (float): The floating-point number to format.

  ## Returns

  - `value` (float): A number formatted to the appropriate precision.

  ## Examples

      iex> TradingApp.NumberFormatter.dynamic_format(1234.56789)
      1234.57

      iex> TradingApp.NumberFormatter.dynamic_format(0.12345678)
      0.1235

      iex> TradingApp.NumberFormatter.dynamic_format(0.000012345678)
      0.00001235

      iex> TradingApp.NumberFormatter.dynamic_format(0.00000012345678)
      0.00000012

  """
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

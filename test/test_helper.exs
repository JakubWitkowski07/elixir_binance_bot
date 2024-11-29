ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(ElixirBinanceBot.Repo, :manual)

defmodule ElixirBinanceBot.TestHelpers do
  @doc """
  Converts errors in a changeset into a map of human-readable error messages.

  ## Examples

      iex> changeset = %Ecto.Changeset{
      ...>   valid?: false,
      ...>   errors: [symbol: {"can't be blank", []}]
      ...> }
      iex> errors_on(changeset)
      %{symbol: ["can't be blank"]}

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end

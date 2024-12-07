defmodule TradingApp.DatabaseListener do
  alias Phoenix.PubSub
  use GenServer

  @channel "transactions_changes"

  defstruct [:ref, :pid]

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, pid} = Postgrex.Notifications.start_link(TradingApp.Repo.config())
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)
    {:ok, %__MODULE__{pid: pid, ref: ref}}
  end

  def handle_info({:notification, pid, ref, @channel, payload}, %{pid: pid, ref: ref} = state) do
    change = Jason.decode!(payload)
    PubSub.broadcast(TradingInterface.PubSub, "transactions", change)
    {:noreply, state}
  end
end

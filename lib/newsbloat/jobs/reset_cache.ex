defmodule Newsbloat.Jobs.ResetCache do
  use GenServer

  alias Newsbloat.Cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    # Schedule work to be performed on start
    schedule_work()

    {:ok, state}
  end

  @impl true
  def handle_info(:work, state) do
    IO.puts("Clearing cache...")
    Cache.reset()
    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.hours(24))
  end
end

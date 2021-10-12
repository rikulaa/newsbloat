defmodule Newsbloat.Jobs.FetchNewFeedItems do
  use GenServer

  alias Newsbloat.RSS

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
    # Do the desired work here
    # ...
    IO.puts("Fetching new feed items...")
    RSS.fetch_feed_items_for_all_feeds()
    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.hours(1))
  end
end

defmodule Mix.Tasks.RSS.FetchNewFeedItems do
  use Mix.Task

  alias Newsbloat.RSS

  @requirements ["app.start"]
  @shortdoc "Fetch new feed items"

  @impl Mix.Task
  def run(_args) do
    RSS.fetch_feed_items_for_all_feeds()
  end
end

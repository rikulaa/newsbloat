defmodule Mix.Tasks.Rss.FetchNewFeedItems do
  use Mix.Task

  alias Newsbloat.RSS

  @shortdoc "Fetch new feed items"
  @moduledoc "Fetch new feed items"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    RSS.fetch_feed_items_for_all_feeds()
  end
end

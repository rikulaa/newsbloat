defmodule Mix.Tasks.Rss.ResetCache do
  use Mix.Task

  alias Newsbloat.Cache

  @requirements ["app.start"]
  @shortdoc "Reset application cache"

  @impl Mix.Task
  def run(_args) do
    IO.puts("Clearing cache...")
    Cache.reset()
  end
end

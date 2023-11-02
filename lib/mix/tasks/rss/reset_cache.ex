defmodule Mix.Tasks.Rss.ResetCache do
  use Mix.Task

  alias Newsbloat.Cache

  @shortdoc "Reset application cache"
  @moduledoc "Reset application cache"
  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    IO.puts("Clearing cache...")
    Cache.reset()
  end
end

defmodule NewsbloatWeb.FeedLive.FeedListComponent do
  use NewsbloatWeb, :live_component

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  def update(assigns, socket) do
    {:ok, assign(socket, :feeds, list_feeds())}
  end


  defp list_feeds do
    RSS.list_feeds()
  end


  def render(assigns) do
    ~L"""
    <section>
    <h3>Feeds</h3>

    <ul>
      <%= for feed <- @feeds do %>
        <li>
          <span><%= live_redirect feed.title, to: Routes.feed_show_path(@socket, :show, feed) %></span>
        </li>


      <%= end %>
      <li>
        <span><%= live_patch "New Feed", to: Routes.feed_index_path(@socket, :new) %></span>
      </li>
    </ul>

    </section>
    """
  end

end

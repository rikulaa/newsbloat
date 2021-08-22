defmodule NewsbloatWeb.FeedLive.FeedListComponent do
  use NewsbloatWeb, :live_component

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  def update(assigns, socket) do
    {:ok, assign(socket, :feeds, list_feeds())}
  end


  defp list_feeds do
    RSS.list_feeds()
    |> Enum.map(fn (feed) ->
      %{
        :feed => feed,
        :unread_count => RSS.get_feed_items_unread_count!(feed)
      }
      
    end)
  end


  def render(assigns) do
    ~L"""
    <section>
    <h3>Feeds</h3>

    <ul>
      <%= for %{ :feed => feed, :unread_count => unread_count } <- @feeds do %>
        <li>
        <span><%= live_redirect feed.title, to: Routes.feed_show_path(@socket, :show, feed) %> <%= if unread_count != 0 do "("<>to_string(unread_count)<>")" end %></span>
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

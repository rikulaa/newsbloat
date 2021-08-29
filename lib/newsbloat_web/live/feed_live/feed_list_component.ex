defmodule NewsbloatWeb.FeedLive.FeedListComponent do
  use NewsbloatWeb, :live_component

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  def update(assings, socket) do
    {:ok,
     socket
     |> assign(:current_feed, Map.get(assings, :current_feed, %Feed{}))
     |> assign(:feeds, list_feeds())}
  end

  defp list_feeds do
    RSS.list_feeds()
    |> Enum.map(fn feed ->
      %{
        :feed => feed,
        :unread_count => RSS.get_feed_items_unread_count!(feed)
      }
    end)
  end

  def render(assigns) do
    get_feed_title = fn (feed, unread_count) ->
      if unread_count != 0 do
        feed.title <> " (" <> to_string(unread_count) <> ")"
      else
        feed.title
      end
    end

    ~L"""
    <section class="fixed top-0 p-4">
    <h3>Feeds</h3>

    <ul>
      <%= for %{ :feed => feed, :unread_count => unread_count } <- @feeds do %>
        <li>
        <%= live_redirect get_feed_title.(feed, unread_count),
          to: Routes.feed_show_path(@socket, :show, feed),
          class: if @current_feed.id == feed.id, do: "w-full active", else: "w-full"
        %>
        </span>
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

defmodule NewsbloatWeb.FeedListComponent do
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
    page = RSS.list_feeds()

    page
    |> Enum.map(fn feed ->
      %{
        :feed => feed,
        # TODO: probably should fetch unread count with the same query, not like this
        :unread_count => RSS.get_feed_items_unread_count!(feed)
      }
    end)
  end

  # TODO: this component should be at root level with connected socket (without needing to do full re-render on page changes)
  def render(assigns) do
    get_feed_title = fn feed, unread_count ->
      if unread_count != 0 do
        feed.title <> " (" <> to_string(unread_count) <> ")"
      else
        feed.title
      end
    end

    ~L"""
    <ul class="mb-4">
      <%= for %{ :feed => feed, :unread_count => unread_count } <- @feeds do %>
        <li>
          <%= live_redirect get_feed_title.(feed, unread_count), to: Routes.feed_show_path(@socket, :show, feed), class: if @current_feed.id == feed.id, do: "link p-2 w-full truncate active", else: "link p-2 truncate w-full" %>
        </li>
      <% end %>
    </ul>

    """
  end
end

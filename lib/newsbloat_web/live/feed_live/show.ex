defmodule NewsbloatWeb.FeedLive.Show do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  alias NewsbloatWeb.Router.Helpers, as: Routes

  @impl true
  def mount(%{ "id" => id } = _params, _session, socket) do
    {:ok, assign(socket, :id, id)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    feed = RSS.get_feed!(id)
    item_id = params
              |> Map.get("item_id")
              |> (fn (id) -> if id do String.to_integer(id) else nil end end).()

    if item_id do
      item = RSS.get_feed_item(feed, item_id)
      RSS.mark_item_as_read(item)
    end

    page = RSS.list_feed_items(feed)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:feed, feed)
     |> assign(:page, page)
     |> assign(:item_id, item_id)
    }
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed")
    |> assign(:feed, %Feed{})
  end

  @impl true
  def handle_event("refresh_feed", _, socket) do
    {:ok, _ } = Newsbloat.RSS.fetch_feed_items(socket.assigns.feed)
    {:noreply, push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end

  def handle_event("mark_all_as_read", _, socket) do
    {:ok, _ } = Newsbloat.RSS.mark_all_feed_items_as_read(socket.assigns.feed)
    {:noreply, push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end



  defp page_title(:show), do: "Show Feed"
  defp page_title(:edit), do: "Edit Feed"
  defp page_title(:new), do: "New Feed"
end

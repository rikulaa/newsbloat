defmodule NewsbloatWeb.FeedLive.ShowItem do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS

  @impl true
  def mount(%{"id" => id, "item_id" => item_id} = _params, session, socket) do
    {:ok,
     socket
     |> assign_defaults_from_session(session)
     |> initialize(id, item_id)}
  end

  defp initialize(socket, id, item_id) do
    feed = RSS.get_feed!(id)
    item = RSS.get_feed_item(feed, item_id)

    socket
    |> assign(:id, id)
    |> assign(:feed, feed)
    |> assign(:item, item)
    |> assign(:page_title, page_title(socket.assigns.live_action))
  end

  # Add to favourites/remove from favourites
  @impl true
  def handle_event(
        "mark_as_favoured",
        %{"item_id" => item_id} = _params,
        %{assigns: assigns} = socket
      ) do
    item = RSS.get_feed_item(assigns.feed, String.to_integer(item_id))
    {:ok, updated_item} = RSS.mark_item_as_favoured(item)
    socket = update_item_in_place_in_socket(socket, updated_item)
    {:noreply, socket}
  end

  def handle_event(
        "mark_as_non_favoured",
        %{"item_id" => item_id} = _params,
        %{assigns: assigns} = socket
      ) do
    item = RSS.get_feed_item(assigns.feed, String.to_integer(item_id))
    {:ok, updated_item} = RSS.mark_item_as_non_favoured(item)
    socket = update_item_in_place_in_socket(socket, updated_item)
    {:noreply, socket}
  end

  # Replaces the provided item with new value inside the socket
  defp update_item_in_place_in_socket(socket, item) do
    socket
    |> assign(:item, item)
  end

  defp page_title(:show), do: NewsbloatWeb.Gettext.gettext("Show Item")
end

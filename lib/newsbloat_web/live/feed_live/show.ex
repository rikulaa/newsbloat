defmodule NewsbloatWeb.FeedLive.Show do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  alias NewsbloatWeb.Router.Helpers, as: Routes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    feed = RSS.get_feed!(id)
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:feed, feed)
     |> assign(:items, RSS.get_feed_items(feed))
    }
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed")
    |> assign(:feed, %Feed{})
  end

  def handle_event("refresh_feed", _, socket) do
    {:ok, _ } = Newsbloat.RSS.fetch_feed_items(socket.assigns.feed)
    {:noreply, push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end


  defp page_title(:show), do: "Show Feed"
  defp page_title(:edit), do: "Edit Feed"
  defp page_title(:new), do: "New Feed"
end

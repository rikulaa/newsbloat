defmodule NewsbloatWeb.FeedLive.Index do
  import Phoenix.LiveView.Helpers
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign_defaults_from_session(session)
     |> assign(:feeds, list_feeds())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Feed")
    |> assign(:feed, RSS.get_feed!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Feed")
    |> assign(:feed, %Feed{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Feeds")
    |> assign(:feed, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    feed = RSS.get_feed!(id)
    {:ok, _} = RSS.delete_feed(feed)

    {:noreply, assign(socket, :feeds, list_feeds())}
  end

  defp list_feeds do
    RSS.list_feeds()
  end
end

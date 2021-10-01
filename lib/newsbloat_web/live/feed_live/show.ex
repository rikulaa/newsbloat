defmodule NewsbloatWeb.FeedLive.Show do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  alias NewsbloatWeb.Router.Helpers, as: Routes

  @impl true
  def mount(%{ "id" => id } = _params, _session, socket) do
    {:ok, socket 
    |> initialize(id)
    }
  end

  @impl true
  def handle_params(%{"id" => _id} = params, _, %{ assigns: assigns } = socket) do
    # TODO: id might change here in case we are using live_patch (instead of redirect)
    feed = RSS.get_feed!(assigns.id)
    item_id = params
              |> Map.get("item_id")
              |> (fn (id) -> if id do String.to_integer(id) else nil end end).()

    # expand the selected item, NOTE: this can become slow after many too many loaded entries, should probably implement more efficient way to show the read status in the ui
    if item_id do
      {:ok, item } = RSS.get_feed_item(feed, item_id) |> RSS.mark_item_as_read()
      socket = socket
               |> assign(:page, assigns.page |> Map.put(:entries, assigns.page.entries |> Enum.map(fn entry -> if entry.id == item.id, do: item, else: entry end)))

      {:noreply,
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:item_id, item_id)
      }
    else
      {:noreply,
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:item_id, item_id)
      }
    end
  end

  defp initialize(%{ assigns: _assigns } = socket, id) do
    feed = RSS.get_feed!(id)
    socket
    |> assign(:id, id)
    |> assign(:feed, feed)
    |> assign(:page, fetch_page_by_number(feed, 1))
  end

  defp fetch_page_by_number(feed, page) do
    RSS.list_feed_items(feed, page)
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

  def handle_event("mark_all_as_read", _, socket) do
    {:ok, _ } = Newsbloat.RSS.mark_all_feed_items_as_read(socket.assigns.feed)
    {:noreply, push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end

  def handle_event("load_more", _, %{ assigns: assigns } = socket) do
    current_page_number = assigns |> Map.get(:page, %{}) |> Map.get(:page_number, 1)
    total_pages = assigns |> Map.get(:page, %{}) |> Map.get(:total_pages, 1)

    if current_page_number < total_pages do
      existing_items = assigns |> Map.get(:page, %{}) |> Map.get(:entries, [])
      new_page = fetch_page_by_number(assigns.feed, current_page_number + 1)
      new_page = new_page |> Map.put(:entries, existing_items ++ new_page.entries)

      {:noreply, socket |> assign(:page, new_page)}
    else
      {:noreply, socket }
    end
  end




  defp page_title(:show), do: "Show Feed"
  defp page_title(:edit), do: "Edit Feed"
  defp page_title(:new), do: "New Feed"
end

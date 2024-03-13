defmodule NewsbloatWeb.FeedLive.Show do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS

  alias NewsbloatWeb.Router.Helpers, as: Routes

  @impl true
  def mount(%{"id" => id} = params, session, socket) do
    {_, opts_map} = params |> Map.pop("id")

    default_opts =
      opts_map |> Map.update("is_read", false, fn prev_val -> prev_val end) |> Map.to_list()

    {:ok,
     socket
     |> assign_defaults_from_session(session)
     |> initialize(id, default_opts)}
  end

  @impl true
  def handle_params(%{"id" => _id} = params, _, %{assigns: assigns} = socket) do
    # TODO: id might change here in case we are using live_patch (instead of redirect)
    # feed = RSS.get_feed!(assigns.id)

    open_id =
      params
      |> Map.get("open_id")
      |> maybe_string_to_integer()

    close_id =
      params
      |> Map.get("close_id")
      |> maybe_string_to_integer()

    # expand the selected item, NOTE: this can become slow after many too many loaded entries, should probably implement more efficient way to show the read status in the ui
    if open_id do
      {:ok, item} = RSS.get_feed_item(assigns.feed, open_id) |> RSS.mark_item_as_read()

      socket =
        update_item_in_place_in_socket(socket, item)
        |> assign(:opened_ids, Map.put(socket.assigns.opened_ids, open_id, true))

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:item_id, open_id)}
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:item_id, nil)
       |> assign(:opened_ids, Map.delete(socket.assigns.opened_ids, close_id))}
    end
  end

  defp initialize(%{assigns: _assigns} = socket, id, opts) do
    feed = RSS.get_feed!(id)

    kw_opts = Enum.map(opts, fn {key, value} -> {String.to_existing_atom(key), value} end)

    socket
    |> assign(:id, id)
    |> assign(:feed, feed)
    |> assign(:page, fetch_page_by_number(feed, 1, kw_opts))
    |> assign(:opened_ids, %{})
    |> assign(:previous_id, nil)
  end

  defp fetch_page_by_number(feed, page, opts \\ []) do
    RSS.list_feed_items(feed, page, opts)
  end

  @impl true
  def handle_event("refresh_feed", _, socket) do
    {:ok, _} = Newsbloat.RSS.fetch_feed_items(socket.assigns.feed)

    {:noreply,
     push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end

  def handle_event("mark_all_as_read", _, socket) do
    {:ok, _} = Newsbloat.RSS.mark_all_feed_items_as_read(socket.assigns.feed)

    {:noreply,
     push_redirect(socket, to: Routes.feed_show_path(socket, :show, socket.assigns.feed))}
  end

  def handle_event("load_more", _, %{assigns: assigns} = socket) do
    current_page_number = assigns |> Map.get(:page, %{}) |> Map.get(:page_number, 1)
    total_pages = assigns |> Map.get(:page, %{}) |> Map.get(:total_pages, 1)

    if current_page_number < total_pages do
      existing_items = assigns |> Map.get(:page, %{}) |> Map.get(:entries, [])
      new_page = fetch_page_by_number(assigns.feed, current_page_number + 1)
      new_page = new_page |> Map.put(:entries, existing_items ++ new_page.entries)

      # If we fetch the last entries, we mark them as read as well (as we are not calling this function again)
      items_to_mark_read =
        if current_page_number === total_pages - 1,
          do: existing_items ++ new_page.entries,
          else: existing_items

      RSS.mark_feed_items_as_read(assigns.feed, items_to_mark_read)

      {:noreply, socket |> assign(:page, new_page)}
    else
      {:noreply, socket}
    end
  end

  # Add to favourites/remove from favourites
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
  defp update_item_in_place_in_socket(%{assigns: assigns} = socket, item) do
    socket
    |> assign(
      :page,
      assigns.page
      |> Map.put(
        :entries,
        assigns.page.entries
        |> Enum.map(fn entry -> if entry.id == item.id, do: item, else: entry end)
      )
    )
  end

  defp page_title(:show), do: NewsbloatWeb.Gettext.gettext("Show Feed")
  defp page_title(:edit), do: NewsbloatWeb.Gettext.gettext("Edit Feed")
  defp page_title(:new), do: NewsbloatWeb.Gettext.gettext("New Feed")

  defp maybe_string_to_integer(string) when is_binary(string), do: String.to_integer(string)
  defp maybe_string_to_integer(_), do: nil
end

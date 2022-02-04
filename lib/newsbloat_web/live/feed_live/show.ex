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
    IO.inspect(["assign", Map.keys(assigns), assigns[:ui_theme]])
    # TODO: id might change here in case we are using live_patch (instead of redirect)
    feed = RSS.get_feed!(assigns.id)
    show_is_read = params |> Map.get("is_read", false) == true

    item_id =
      params
      |> Map.get("item_id")
      |> (fn id ->
            if id do
              String.to_integer(id)
            else
              nil
            end
          end).()

    # expand the selected item, NOTE: this can become slow after many too many loaded entries, should probably implement more efficient way to show the read status in the ui
    if item_id do
      {:ok, item} = RSS.get_feed_item(feed, item_id) |> RSS.mark_item_as_read()
      socket = update_item_in_place_in_socket(socket, item)

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:item_id, item_id)}
    else
      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:item_id, item_id)}
    end
  end

  defp initialize(%{assigns: _assigns} = socket, id, opts \\ []) do
    feed = RSS.get_feed!(id)

    kw_opts = Enum.map(opts, fn {key, value} -> {String.to_existing_atom(key), value} end)

    socket
    |> assign(:id, id)
    |> assign(:feed, feed)
    |> assign(:page, fetch_page_by_number(feed, 1, kw_opts))
  end

  defp fetch_page_by_number(feed, page, opts \\ []) do
    RSS.list_feed_items(feed, page, opts)
  end

  # defp apply_action(socket, :new, _params) do
  #   socket
  #   |> assign(:page_title, "New Feed")
  #   |> assign(:feed, %Feed{})
  # end

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
end

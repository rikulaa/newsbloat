defmodule NewsbloatWeb.FeedLive.FormComponent do
  use NewsbloatWeb, :live_component

  alias Newsbloat.RSS

  @impl true
  def update(%{feed: feed} = assigns, socket) do
    changeset = RSS.change_feed(feed)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:tried_to_populate, false)}
  end

  @impl true
  def handle_event("validate", %{"feed" => feed_params}, socket) do
    has_only_url =
      String.length(feed_params["url"]) > 0 and
        Enum.all?([feed_params["title"], feed_params["description"]], fn s ->
          is_nil(s) or String.length(s) == 0
        end)

    # TODO: should validate this via changesets?
    is_valid_url = !is_nil(URI.parse(feed_params["url"]).host)

    not_persisted = is_nil(Map.get(socket.assigns.feed, :id))

    if not socket.assigns.tried_to_populate and not_persisted and has_only_url and is_valid_url do
      maybe_populated_feed =
        RSS.maybe_populate_feed_title_and_description(%{} |> Map.put(:url, feed_params["url"]))

      changeset =
        socket.assigns.feed
        |> RSS.change_feed(maybe_populated_feed)
        |> Map.put(:action, :validate)

      {:noreply,
       socket
       |> assign(:changeset, changeset)
       |> assign(:tried_to_populate, true)}
    else
      changeset =
        socket.assigns.feed
        |> RSS.change_feed(feed_params)
        |> Map.put(:action, :validate)

      {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("save", %{"feed" => feed_params}, socket) do
    save_feed(socket, socket.assigns.action, feed_params)
  end

  def handle_event("delete", %{"id" => id}, socket) do
    feed = RSS.get_feed!(id)
    {:ok, _} = RSS.delete_feed(feed)

    {
      :noreply,
      socket
      |> put_flash(:info, "Feed deleted")
      |> push_redirect(to: Routes.feed_index_path(socket, :index))
    }
  end

  defp save_feed(socket, :edit, feed_params) do
    case RSS.update_feed(socket.assigns.feed, feed_params) do
      {:ok, _feed} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feed updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_feed(socket, :new, feed_params) do
    case RSS.create_feed(feed_params) do
      {:ok, _feed} ->
        {:noreply,
         socket
         |> put_flash(:info, "Feed created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

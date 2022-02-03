defmodule NewsbloatWeb.SearchLive.Index do
  use NewsbloatWeb, :live_view

  alias Newsbloat.RSS
  alias Newsbloat.RSS.Feed

  @impl true
  def mount(params, session, socket) do
    {:ok,
     socket
     |> assign_defaults_from_session(session)
     |> assign(:q, params |> Map.get("q", ""))
     |> assign(:results, %{})
     |> assign(:is_loading, false)}
  end

  def handle_params(params, _, %{assigns: assigns} = socket) do
    # Get 'q' param, fetch results with that
    q = params |> Map.get("q", "")

    results =
      if String.length(q) > 0 do
        RSS.search_items(q)
      else
        []
      end

    {:noreply,
     socket
     |> assign(:results, results)
     |> assign(:q, q)
     |> assign(:is_loading, false)}
  end

  @impl true
  def handle_event("search", params, socket) do
    search_string = params |> Map.get("input", "")

    {:noreply,
     socket
     |> assign(:is_loading, true)
     |> push_patch(to: Routes.search_index_path(socket, :index, %{"q" => search_string}))}
  end
end

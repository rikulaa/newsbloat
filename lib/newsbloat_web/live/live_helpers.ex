defmodule NewsbloatWeb.LiveHelpers do
  import Phoenix.LiveView.Helpers
  import Phoenix.LiveView, only: [assign_new: 3]

  @doc """
  Renders a component inside the `NewsbloatWeb.ModalComponent` component.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <%= live_modal @socket, NewsbloatWeb.FeedLive.FormComponent,
        id: @feed.id || :new,
        action: @live_action,
        feed: @feed,
        return_to: Routes.feed_index_path(@socket, :index) %>
  """
  def live_modal(socket, component, opts) do
    path = Keyword.fetch!(opts, :return_to)
    modal_opts = [id: :modal, return_to: path, component: component, opts: opts]
    live_component(socket, NewsbloatWeb.ModalComponent, modal_opts)
  end

  @doc """
  Sets 'default' assigns to the socket
  """
  def assign_defaults_from_session(socket, session) do
    socket =
      socket
      |> assign_new(:ui_theme, fn -> Map.get(session, "ui_theme") end)
    socket
  end
end

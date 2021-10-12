defmodule NewsbloatWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use NewsbloatWeb, :controller
      use NewsbloatWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: NewsbloatWeb

      import Plug.Conn
      import NewsbloatWeb.Gettext
      alias NewsbloatWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/newsbloat_web/templates",
        namespace: NewsbloatWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())

      def render_component(template, assigns \\ []) do
        render(NewsbloatWeb.ComponentView, template, assigns)
      end
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {NewsbloatWeb.LayoutView, "live.html"}

      unquote(view_helpers())

      def render_component(template, assigns \\ []) do
        render(NewsbloatWeb.ComponentView, template, assigns)
      end
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())

      def render_component(template, assigns \\ []) do
        render(NewsbloatWeb.ComponentView, template, assigns)
      end
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import NewsbloatWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers
      import NewsbloatWeb.LiveHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import NewsbloatWeb.ErrorHelpers
      import NewsbloatWeb.Gettext
      alias NewsbloatWeb.Router.Helpers, as: Routes

      def current_ui_theme(%Plug.Conn{} = conn) do
        Plug.Conn.get_session(conn, :ui_theme)
      end

      def icon_tag(conn, name, opts \\ []) do
        classes = Keyword.get(opts, :class, "") <> " icon"
        svg_starting_tag_with_classes = "<svg class='" <> classes <> "'"

        # TODO: cache these
        svg_tag =
          File.read!("priv/static/icons/" <> name <> ".svg")
          # Yeah, not the most safe solution to manipulate html with regex...
          |> String.replace("<svg", svg_starting_tag_with_classes)
          |> raw()
      end

      def link_with_html(opts, do: content) do
        link(content |> raw(), opts)
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

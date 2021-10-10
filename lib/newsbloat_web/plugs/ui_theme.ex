defmodule NewsbloatWeb.Plugs.UITheme do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{query_params: %{"ui_theme" => ui_theme}} = conn, _default) do
    conn
    |> assign(:ui_theme, ui_theme)
    |> put_session(:ui_theme, ui_theme)
    |> put_resp_cookie("ui-theme", ui_theme)
  end

  def call(conn, _default) do
    # TODO: Should initially respect the browsers 'prefers color scheme' value
    default_ui_theme = conn.cookies |> Map.get("ui-theme", "dark")

    conn
    |> assign(:ui_theme, default_ui_theme)
    |> put_session(:ui_theme, default_ui_theme)
    |> put_resp_cookie("ui-theme", default_ui_theme)
  end
end

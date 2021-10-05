defmodule NewsbloatWeb.Plugs.UITheme do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{query_params: %{"ui_theme" => ui_theme}} = conn, _default) do
    assign(conn, :ui_theme, ui_theme)
    |> put_session(:ui_theme, ui_theme)
  end

  def call(conn, default) do
    assign(conn, :ui_theme, "dark")
    |> put_session(:ui_theme, "dark")
  end
end

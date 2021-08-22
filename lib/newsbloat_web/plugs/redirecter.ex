defmodule NewsbloatWeb.Plugs.Redirecter do
  import Plug.Conn

  alias Phoenix.Controller

  def init([to: _] = opts), do: opts

  def call(%Plug.Conn{} = conn, opts) do
    Controller.redirect(conn, opts)
  end

end

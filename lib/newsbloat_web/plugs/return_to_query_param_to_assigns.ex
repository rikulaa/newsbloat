defmodule NewsbloatWeb.Plugs.ReturnToQueryParamToAssigns do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{query_params: %{"return_to" => return_to}} = conn, _default) do
    assign(conn, :return_to, return_to)
    |> put_session(:return_to, return_to)
  end

  def call(conn, default) do
    IO.puts("PLUG MIDDLEWARE")
    assign(conn, :return_to, nil)
    |> put_session(:return_to, nil)
  end
end

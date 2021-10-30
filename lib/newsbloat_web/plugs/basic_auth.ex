defmodule NewsbloatWeb.Plugs.BasicAuth do
  # Does not actually follow the 'Plug module' structure, this is more like helper function
  # https://hexdocs.pm/plug/1.12.1/Plug.BasicAuth.html#module-runtime-time-usage
  def auth(conn, _opts) do
    if System.get_env("USE_BASIC_AUTH", "false") == "true" do
      username = System.fetch_env!("AUTH_USERNAME")
      password = System.fetch_env!("AUTH_PASSWORD")
      Plug.BasicAuth.basic_auth(conn, username: username, password: password)
    else
      conn
    end
  end
end

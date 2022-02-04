defmodule NewsbloatWeb.Plugs.PutLanguage do
  require NewsbloatWeb.Gettext

  def init(default), do: default

  def call(%Plug.Conn{} = conn, _default) do
    current_lang = Plug.Conn.get_session(conn, :current_lang)
    lang_from_params = conn.params |> Map.get("_lang")

    maybe_assign_lang_to_session = fn conn, lang_iso ->
      known_locales = Gettext.known_locales(NewsbloatWeb.Gettext)

      if Enum.member?(known_locales, lang_iso) do
        Gettext.put_locale(NewsbloatWeb.Gettext, lang_iso)

        conn
        |> Plug.Conn.put_session(:current_lang, lang_iso)
      else
        conn
      end
    end

    cond do
      !is_nil(lang_from_params) ->
        conn
        |> maybe_assign_lang_to_session.(lang_from_params)

      is_nil(current_lang) ->
        accept_language =
          conn
          |> Map.get(:req_headers, [])
          |> Enum.find(fn {key, _} -> key == "accept-language" end)

        case accept_language do
          {_, lang_string} ->
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language
            lang_iso = String.split(lang_string, "-") |> List.first()

            conn
            |> maybe_assign_lang_to_session.(lang_iso)

          _ ->
            conn
        end

      true ->
        conn
    end
  end
end

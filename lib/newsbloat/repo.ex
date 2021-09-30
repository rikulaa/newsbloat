defmodule Newsbloat.Repo do
  use Ecto.Repo,
    otp_app: :newsbloat,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 25
end

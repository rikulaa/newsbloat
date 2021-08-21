defmodule Newsbloat.Repo do
  use Ecto.Repo,
    otp_app: :newsbloat,
    adapter: Ecto.Adapters.Postgres
end

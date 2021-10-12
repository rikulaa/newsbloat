defmodule Newsbloat.Repo.Migrations.AddFavouritesTag do
  use Ecto.Migration
  import Ecto.Query, warn: false
  alias Newsbloat.Repo
  alias Newsbloat.RSS.Tag

  def up do
    %Tag{}
    |> Tag.changeset(%{title: "Favourite"})
    |> Repo.insert()
  end

  def down do
    tag = Repo.one(from(t in Tag, where: t.title == "Favourite"))

    tag
    |> Repo.delete()
  end
end

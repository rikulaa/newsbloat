defmodule Newsbloat.RSS.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:title])
    |> validate_required([:title])
    |> unique_constraint(:title)
  end
end

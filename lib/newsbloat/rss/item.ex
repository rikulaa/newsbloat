defmodule Newsbloat.RSS.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias Newsbloat.RSS.Feed

  schema "items" do
    field :content, :string
    field :description, :string
    field :guid, :string
    field :link, :string
    field :published_at, :utc_datetime
    field :title, :string
    field :is_read, :boolean
    belongs_to :feed, Feed

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:title, :link, :description, :guid, :published_at, :content, :is_read])
    |> validate_required([:title, :link, :guid, :published_at])
    |> unique_constraint(:guid)
  end
end

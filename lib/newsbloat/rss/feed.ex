defmodule Newsbloat.RSS.Feed do
  use Ecto.Schema
  import Ecto.Changeset

  alias Newsbloat.RSS.Item
  alias Newsbloat.RSS.Tag

  schema "feeds" do
    field :description, :string
    field :url, :string
    field :title, :string
    has_many :items, Item
    many_to_many :tags, Tag, join_through: "feed_tags"

    timestamps()
  end

  @doc false
  def changeset(feed, attrs) do
    feed
    |> cast(attrs, [:title, :url, :description])
    |> validate_required([:title, :url])
  end
end

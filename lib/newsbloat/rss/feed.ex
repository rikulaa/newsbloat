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
    |> validate_url(:url)
  end

  @doc """
  Validates a change has the proper url format

  ## Examples

      validate_url(changeset, :email)

  """
  # @spec validate_url(t, atom, Keyword.t()) :: t
  def validate_url(changeset, field) do
    validate_change(changeset, field, fn
      _, value ->
        if !is_nil(URI.parse(value).host), do: [], else: [{field, "Invalid URL"}]
    end)
  end
end

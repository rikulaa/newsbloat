defmodule Newsbloat.RSS.Item do
  use Ecto.Schema
  import Ecto.Changeset

  alias Newsbloat.RSS.Item
  alias Newsbloat.RSS.Feed
  alias Newsbloat.RSS.Tag
  alias HtmlSanitizeEx

  schema "items" do
    field :content, :string
    field :safe_content, :string, virtual: true
    field :description, :string
    field :safe_description, :string, virtual: true
    field :guid, :string
    field :link, :string
    field :published_at, :utc_datetime
    # TODO: this should be a text field (in db)
    field :title, :string
    field :is_read, :boolean
    belongs_to :feed, Feed
    many_to_many :tags, Tag,
      join_through: "item_tags"

    timestamps()
  end

  # TODO: maybe cache these ?
  @spec with_safe_content_and_desc(%Item{}) :: %Item{}
  def with_safe_content_and_desc(%Item{ content: content, description: description } = item) do
    %{ item | safe_content: HtmlSanitizeEx.basic_html(content), safe_description: HtmlSanitizeEx.basic_html(description) }
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:title, :link, :description, :guid, :published_at, :content, :is_read])
    |> validate_required([:title, :link, :guid, :published_at])
    |> unique_constraint(:guid)
  end
end

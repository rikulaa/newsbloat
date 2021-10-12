defmodule Newsbloat.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :title, :string

      timestamps()
    end

    create unique_index(:tags, [:title])

    # Primary key and timestamps are not required if
    # using many_to_many without schemas
    create table("feed_tags", primary_key: false) do
      add :feed_id, references(:feeds)
      add :tag_id, references(:tags)
      # timestamps()
    end

    # Primary key and timestamps are not required if
    # using many_to_many without schemas
    create table("item_tags", primary_key: false) do
      add :item_id, references(:items)
      add :tag_id, references(:tags)
      # timestamps()
    end
  end
end

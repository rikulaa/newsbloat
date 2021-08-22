defmodule Newsbloat.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :title, :string
      add :link, :string
      add :description, :text
      add :guid, :string
      add :published_at, :utc_datetime
      add :content, :text
      add :feed_id, references(:feeds, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:items, [:feed_id])
    create unique_index(:items, [:guid])
  end
end

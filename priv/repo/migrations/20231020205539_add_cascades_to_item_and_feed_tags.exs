defmodule Newsbloat.Repo.Migrations.AddCascadesToItemAndFeedTags do
  use Ecto.Migration

  def change do
    alter table("feed_tags") do
      modify :feed_id, references(:feeds, on_delete: :delete_all), from: references(:feeds)
      modify :feed_id, :integer, null: false
      modify :tag_id, :integer, null: false
    end

    alter table("item_tags") do
      modify :item_id, references(:items, on_delete: :delete_all), from: references(:items)
      modify :item_id, :integer, null: false
      modify :tag_id, :integer, null: false
    end

  end
end

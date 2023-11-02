defmodule Newsbloat.Repo.Migrations.FeedCharColumnsToText do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      modify :description, :text, from: :varchar
      modify :url, :text, from: :varchar
      modify :title, :text, from: :varchar
    end

  end
end

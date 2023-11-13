defmodule Newsbloat.Repo.Migrations.ItemGuidToText do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :guid, :text, from: :varchar
    end

  end
end

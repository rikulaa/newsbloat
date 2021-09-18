defmodule Newsbloat.Repo.Migrations.ChangeItemTitleColumnToText do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :title, :text

    end

  end
end

defmodule Newsbloat.Repo.Migrations.AddIsReadToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :is_read, :boolean, default: false
    end
  end
end

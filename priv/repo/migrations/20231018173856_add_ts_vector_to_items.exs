defmodule Newsbloat.Repo.Migrations.AddTsVectorToItems do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE items ADD COLUMN _search_tsv tsvector"
    execute "CREATE INDEX items_search_tsv_index ON items USING gin(_search_tsv)"
  end

  def down do
    execute "DROP INDEX items_search_tsv_index"
    execute "ALTER TABLE items DROP COLUMN _search_tsv"
  end
end

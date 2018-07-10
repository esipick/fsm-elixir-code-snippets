defmodule Flight.Repo.Migrations.DropUnusedTables do
  use Ecto.Migration

  def change do
    drop(table(:syllabuses))
    drop(table(:flyer_details))
  end
end

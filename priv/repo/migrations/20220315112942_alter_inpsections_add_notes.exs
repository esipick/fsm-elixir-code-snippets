defmodule Flight.Repo.Migrations.AlterInpsectionsAddNotes do
  use Ecto.Migration

  def up do
    alter table(:inspections) do
      add(:notes, :text, default: nil)
    end
  end

  def down do
    alter table(:inspections) do
      remove :notes
    end
  end
end

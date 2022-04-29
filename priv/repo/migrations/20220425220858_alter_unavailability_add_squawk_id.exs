defmodule Flight.Repo.Migrations.AlterUnavailabilityAddSquawkId do
  use Ecto.Migration

  def up do
    alter table(:unavailabilities) do
      add(:squawk_id, references(:squawks, type: :id, on_delete: :nothing))
    end
  end

  def down do
    alter table(:unavailabilities) do
      remove(:squawk_id)
    end
  end
end

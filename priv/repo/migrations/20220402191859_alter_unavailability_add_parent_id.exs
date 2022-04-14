defmodule Flight.Repo.Migrations.AlterUnavailabilityAddParentId do
  use Ecto.Migration

  def up do
    alter table(:unavailabilities) do
      add(:parent_id, :integer)
    end
  end

  def down do
    alter table(:unavailabilities) do
      remove(:parent_id)
    end
  end
end

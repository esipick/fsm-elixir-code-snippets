defmodule Flight.Repo.Migrations.AlterMaintenanceAddCreatorUser do
  use Ecto.Migration

  def up do
    alter table(:maintenance) do
      add(:creator_id, references(:users, type: :id, on_delete: :nothing))
    end
  end

  def down do
    alter table(:maintenance) do
      remove :creator_id
    end
  end
end
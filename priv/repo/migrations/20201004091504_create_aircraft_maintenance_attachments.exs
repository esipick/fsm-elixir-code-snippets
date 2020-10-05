defmodule Flight.Repo.Migrations.CreateAircraftMaintenanceAttachments do
  use Ecto.Migration

  def change do
    create table(:aircraft_maintenance_attachments) do
      add(:title, :string, null: true)
      add(:attachment, :string, null: false)
      
      add(:aircraft_maintenance_id, references(:aircraft_maintenance, type: :binary_id, on_delete: :delete_all))

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

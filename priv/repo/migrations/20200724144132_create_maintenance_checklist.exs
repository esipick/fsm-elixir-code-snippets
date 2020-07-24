defmodule Flight.Repo.Migrations.CreateMaintenanceChecklist do
  use Ecto.Migration

  def change do
    create table(:maintenance_checklist) do
      add(:maintenance_id, references(:maintenance, type: :binary_id, on_delete: :delete_all))
      add(:checklist_id, references(:checklist, type: :binary_id, on_delete: :delete_all))

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

defmodule Flight.Repo.Migrations.CreateMaintenanceChecklist do
  use Ecto.Migration

  def change do
    create table(:maintenance_checklist, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:maintenance_id, references(:maintenance, type: :binary_id, on_delete: :delete_all))
      add(:checklist_id, references(:checklist, type: :binary_id, on_delete: :delete_all))

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end

    create unique_index(:maintenance_checklist, [:maintenance_id, :checklist_id])
  end
end

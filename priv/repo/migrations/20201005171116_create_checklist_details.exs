defmodule Flight.Repo.Migrations.CreateChecklistDetails do
  use Ecto.Migration

  def change do
    create table(:checklist_details, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:status, :string, null: false)
      add(:notes, :string, null: true)
      add(:maintenance_checklist_id, references(:maintenance_checklist, type: :binary_id, on_delete: :delete_all))
      add(:aircraft_maintenance_id, references(:aircraft_maintenance, type: :binary_id, on_delete: :delete_all))
      
      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

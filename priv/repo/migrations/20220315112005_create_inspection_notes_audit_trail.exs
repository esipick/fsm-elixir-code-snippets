defmodule Flight.Repo.Migrations.CreateInspectionNotesAuditTrail do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    create table(:inspection_notes_audit_trail) do
      add :notes, :text, default: nil

      add(:user_id, references(:users, on_delete: :nothing), null: false)
      add(:inspection_id, references(:inspections, on_delete: :nothing), null: false)

      soft_delete_columns()
      timestamps()
    end
  end
end

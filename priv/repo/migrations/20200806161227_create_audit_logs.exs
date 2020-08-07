defmodule Flight.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string, null: false
      add :action_description, :string, null: false
      add :school_id, references(:schools, type: :integer, on_delete: :delete_all), null: false
      add :aircraft_id, references(:aircrafts, type: :integer, on_delete: :delete_all)
      add :user_id, references(:users, type: :integer, on_delete: :nothing)
      add :comment, :text
      add :archived, :boolean, default: false, null: false
      timestamps([:inserted_at, default: fragment("now()")])
    end
  end
end

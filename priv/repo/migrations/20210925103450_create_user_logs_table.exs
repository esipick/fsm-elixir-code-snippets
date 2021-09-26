defmodule Flight.Repo.Migrations.CreateUserLogsTable do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do
    create table(:user_logs) do
      add(:device_id, :string, null: false)
      add(:device_type, :string, null: false)
      add(:session_id, :string, null: false)
      add(:os_version, :string, null: false)
      add(:app_id, :string, null: false)
      add(:app_version, :string, null: false)
      add(:user_id, references(:users, on_delete: :nothing), null: false)
      timestamps()
    end
  end

end

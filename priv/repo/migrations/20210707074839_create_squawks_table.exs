defmodule Flight.Repo.Migrations.CreateSquawksTable do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  def change do

    drop_if_exists table("squawks")

    SquawkSeverity.create_type
    SystemAffected.create_type
    create table(:squawks) do
      add :title, :string
      add :severity, SquawkSeverity.type()
      add(:system_affected, SystemAffected.type())
      add :description, :text
      add :resolved, :boolean, default: false
      add(:user_id, references(:users, on_delete: :nothing), null: true)

      soft_delete_columns()
      timestamps()

    end

    create(index(:squawks, [:title]))
  end
end
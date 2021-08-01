defmodule Flight.Repo.Migrations.AlterTableInspectionsAddUser do
  use Ecto.Migration

  def change do
    alter table(:inspections) do
      add(:user_id, references(:users, on_delete: :nothing))
    end
  end
end

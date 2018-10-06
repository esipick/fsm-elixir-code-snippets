defmodule Flight.Repo.Migrations.AddArchivedToUsersAndSchools do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:archived, :boolean, default: false, null: false)
    end

    alter table(:schools) do
      add(:archived, :boolean, default: false, null: false)
    end
  end
end

defmodule Flight.Repo.Migrations.AddNotesFieldUsersTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notes,  :text, default: nil)
    end
  end
end

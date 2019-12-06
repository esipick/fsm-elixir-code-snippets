defmodule Flight.Repo.Migrations.AddUserIdToInvitations do
  use Ecto.Migration

  def change do
    alter table(:invitations) do
      add :user_id, references(:users, on_delete: :nothing), null: true
    end
  end
end

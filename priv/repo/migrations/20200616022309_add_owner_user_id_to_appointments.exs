defmodule Flight.Repo.Migrations.AddOwnerUserIdToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:owner_user_id, references(:users, on_delete: :nothing))
    end
  end
end

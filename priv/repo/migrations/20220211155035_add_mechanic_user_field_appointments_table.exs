defmodule Flight.Repo.Migrations.AddMechanicUserFieldAppointmentsTable do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:mechanic_user_id, references(:users, on_delete: :nothing))
    end
    create(index(:appointments, [:mechanic_user_id]))
  end
end

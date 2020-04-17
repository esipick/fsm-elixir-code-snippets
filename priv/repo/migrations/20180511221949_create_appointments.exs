defmodule Flight.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments) do
      add(:start_at, :naive_datetime)
      add(:end_at, :naive_datetime)
      add(:instructor_user_id, references(:users, on_delete: :nothing))
      add(:user_id, references(:users, on_delete: :nothing))
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))

      timestamps()
    end

    create(index(:appointments, [:instructor_user_id]))
    create(index(:appointments, [:user_id]))
    create(index(:appointments, [:aircraft_id]))
  end
end

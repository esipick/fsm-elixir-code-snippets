defmodule Flight.Repo.Migrations.CreateUserAircrafts do
  use Ecto.Migration

  def change do
    create table(:user_aircrafts) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))
    end

    create(index(:user_aircrafts, [:user_id]))
    create(index(:user_aircrafts, [:aircraft_id]))

    create(
      unique_index(:user_aircrafts, [:user_id, :aircraft_id],
        name: :user_id_aircraft_id_unique_index
      )
    )
  end
end

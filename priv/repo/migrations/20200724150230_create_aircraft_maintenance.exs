defmodule Flight.Repo.Migrations.CreateAircraftMaintenance do
  use Ecto.Migration

  def change do
    create table(:aircraft_maintenance, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:aircraft_id, references(:aircrafts, on_delete: :delete_all))
      add(:maintenance_id, references(:maintenance, type: :binary_id, on_delete: :delete_all))

      add :start_tach_hours, :integer, default: 0 # tach hours reading at which to start the event

      add :start_time, :naive_datetime, null: true # the start of this maintenance activity for this aircraft
      add :end_time, :naive_datetime, null: true # the end of the activity for this aircraft
      
      add :status, :string, default: "pending"

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end

    create unique_index(:aircraft_maintenance, [:aircraft_id, :maintenance_id])
  end
end

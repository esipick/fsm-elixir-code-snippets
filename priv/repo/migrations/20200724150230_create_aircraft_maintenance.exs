defmodule Flight.Repo.Migrations.CreateAircraftMaintenance do
  use Ecto.Migration

  def change do
    create table(:aircraft_maintenance) do
      add(:aircraft_id, references(:aircrafts, on_delete: :delete_all), primary_key: true)
      add(:maintenance_id, references(:maintenance, type: :binary_id, on_delete: :delete_all), primary_key: true)

      add :tach_hours_diff, :integer, default: 0 # number of hours, the event is scheduled to start before the current tach_time
      
      add :start_time, :naive_datetime, null: true # the start of this maintenance activity for this aircraft
      add :end_time, :naive_datetime, null: true # the end of the activity for this aircraft

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

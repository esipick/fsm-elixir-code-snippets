defmodule Flight.Repo.Migrations.AlterAircraftMaintenanceRemoveUnique do
  use Ecto.Migration

  def up do
    execute "DROP INDEX aircraft_maintenance_aircraft_id_maintenance_id_index;"
    execute "CREATE UNIQUE INDEX one_pending_maintenance ON aircraft_maintenance(aircraft_id, maintenance_id, (status = 'pending')) WHERE status = 'pending';"

    alter table(:aircraft_maintenance) do
      remove :start_time
      remove :end_time

      add :due_tach_hours, :integer, default: 0

      add :start_date, :naive_datetime, null: true
      add :due_date, :naive_datetime, null: true

      add :start_et, :naive_datetime, null: true
      add :end_et, :naive_datetime, null: true
    end
  end

  def down do
    alter table(:aircraft_maintenance) do
      add :start_time, :naive_datetime, null: true
      add :end_time, :naive_datetime, null: true

      remove :due_tach_hours
      remove :start_date
      remove :due_date
      remove :start_et
      remove :end_et
    end
    execute "DROP INDEX one_pending_maintenance;"
    create unique_index(:aircraft_maintenance, [:aircraft_id, :maintenance_id]) # There are duplicate entry in database which causes to stop this index from running 
  end
end

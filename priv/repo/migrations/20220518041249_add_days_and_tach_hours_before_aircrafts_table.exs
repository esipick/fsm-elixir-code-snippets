defmodule Flight.Repo.Migrations.AddDaysAndTachHoursBeforeAircraftsTable do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add :days_before, :integer, default: 30
      add :tach_hours_before, :integer, default: 200
    end
  end
end

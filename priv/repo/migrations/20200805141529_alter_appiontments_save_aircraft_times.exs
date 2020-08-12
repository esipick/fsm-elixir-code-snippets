defmodule Flight.Repo.Migrations.AlterAppiontmentsSaveAircraftTimes do
  use Ecto.Migration

  def up do
    alter table(:appointments) do
      add(:start_tach_time, :integer, null: true)
      add(:end_tach_time, :integer, null: true)

      add(:start_hobbs_time, :integer, null: true)
      add(:end_hobbs_time, :integer, null: true)
    end
  end

  def down do
    alter table(:appointments) do
      remove(:start_tach_time)
      remove(:end_tach_time)

      remove(:start_hobbs_time)
      remove(:end_hobbs_time)
    end
  end
end

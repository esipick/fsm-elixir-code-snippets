defmodule Flight.Repo.Migrations.AlterAppointmentsAddAddPrePostTimes do
  use Ecto.Migration

  def up do
    alter table(:appointments) do
      add(:inst_start_at, :naive_datetime, default: nil)
      add(:inst_end_at, :naive_datetime, default: nil)
      add(:appt_status, :integer, default: -1)
    end
  end

  def down do
    alter table(:appointments) do
      remove(:inst_start_at)
      remove(:inst_end_at)
      remove(:appt_status)
    end
  end
end

defmodule Flight.Repo.Migrations.AlterAppointmentsAddAddPrePostTimes do
  use Ecto.Migration

  def up do
    alter table(:appointments) do
      add(:inst_start_at, :naive_datetime, default: nil)
      add(:inst_end_at, :naive_datetime, default: nil)
    end
  end

  def down do
    alter table(:appointments) do
      remove(:inst_start_at)
      remove(:inst_end_at)
    end
  end
end

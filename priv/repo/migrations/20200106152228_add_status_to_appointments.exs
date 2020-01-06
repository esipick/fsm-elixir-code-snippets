defmodule Flight.Repo.Migrations.AddStatusToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:status, :integer, default: 0)
    end
  end
end

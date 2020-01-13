defmodule Flight.Repo.Migrations.AddArchivedToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:archived, :boolean, default: false)
    end
  end
end

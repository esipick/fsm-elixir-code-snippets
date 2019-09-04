defmodule Flight.Repo.Migrations.AddTypeToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:type, :string, default: "legacy")
    end
  end
end

defmodule Flight.Repo.Migrations.ChangeDefaultAppointmentType do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      modify(:type, :string, default: "lesson")
    end
  end
end

defmodule Flight.Repo.Migrations.AddDemoFlightToAppointments do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add :payer_name, :string
      add :demo, :boolean, default: false
    end
  end
end

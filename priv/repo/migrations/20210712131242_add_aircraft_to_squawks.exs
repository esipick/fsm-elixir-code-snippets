defmodule Flight.Repo.Migrations.AddAircraftToSquawks do
  use Ecto.Migration

  def change do
    alter table(:squawks) do
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing), null: true)
    end
  end
end

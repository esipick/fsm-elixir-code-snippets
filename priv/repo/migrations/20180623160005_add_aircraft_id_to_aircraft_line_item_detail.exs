defmodule Flight.Repo.Migrations.AddAircraftIdToAircraftLineItemDetail do
  use Ecto.Migration

  def change do
    alter table(:aircraft_line_item_details) do
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))
    end

    create(index(:aircraft_line_item_details, [:aircraft_id]))
  end
end

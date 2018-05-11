defmodule Flight.Repo.Migrations.CreateInspections do
  use Ecto.Migration

  def change do
    create table(:inspections) do
      add(:type, :string)
      add(:date_value, :date)
      add(:number_value, :integer)
      add(:name, :string)
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))

      timestamps()
    end

    create(index(:inspections, [:aircraft_id]))
  end
end

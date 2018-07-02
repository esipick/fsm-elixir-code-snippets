defmodule Flight.Repo.Migrations.AddMoreToAircraftDetails do
  use Ecto.Migration

  def change do
    alter table(:aircraft_line_item_details) do
      add(:rate, :integer)
      add(:rate_type, :string)
      add(:fee_percentage, :float)
    end
  end
end

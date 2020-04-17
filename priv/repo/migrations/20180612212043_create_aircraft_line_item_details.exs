defmodule Flight.Repo.Migrations.CreateAircraftLineItemDetails do
  use Ecto.Migration

  def change do
    create table(:aircraft_line_item_details) do
      add(:hobbs_start, :integer)
      add(:hobbs_end, :integer)
      add(:tach_start, :integer)
      add(:tach_end, :integer)
      add(:transaction_line_item_id, references(:transaction_line_items, on_delete: :nothing))

      timestamps()
    end

    create(index(:aircraft_line_item_details, [:transaction_line_item_id]))
  end
end

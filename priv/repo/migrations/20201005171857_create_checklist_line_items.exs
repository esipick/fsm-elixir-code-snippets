defmodule Flight.Repo.Migrations.CreateChecklistLineItems do
  use Ecto.Migration

  def change do
    create table(:checklist_line_items, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:part_name, :string, null: false)
      add(:part_number, :string, null: false)
      add(:serial_number, :string, null: false)
      add(:cost, :integer, default: 0)

      add(:checklist_details_id, references(:checklist_details, type: :binary_id, on_delete: :delete_all))

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

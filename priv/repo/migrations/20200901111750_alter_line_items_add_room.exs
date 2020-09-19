defmodule Flight.Repo.Migrations.AlterLineItemsAddRoom do
  use Ecto.Migration

  def up do
    alter table(:invoice_line_items) do
      add(:room_id, references(:rooms, type: :id, on_delete: :nothing))
    end
  end

  def down do
    alter table(:invoice_line_items) do
      remove :room_id
    end
  end
end

defmodule Flight.Repo.Migrations.AddAircraftIdToInvoiceLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing), null: true)
    end
  end
end

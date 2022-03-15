defmodule Flight.Repo.Migrations.AddMaintenanceInvoiceLineItemsFields do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:name, :string, default: nil)
      add(:serial_number, :string, default: nil)
      add(:notes, :text, default: nil)
    end
  end
end

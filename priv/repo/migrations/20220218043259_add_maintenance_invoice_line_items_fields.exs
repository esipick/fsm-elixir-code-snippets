defmodule Flight.Repo.Migrations.AddMaintenanceInvoiceLineItemsFields do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:part_number, :string, default: nil)
      add(:part_cost, :integer, default: nil)
      add(:part_name, :string, default: nil)
      add(:part_description, :string, default: nil)
    end
  end
end

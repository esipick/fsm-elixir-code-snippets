defmodule Flight.Repo.Migrations.AddTypeToInvoiceLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:type, :integer, default: 0)
    end
  end
end

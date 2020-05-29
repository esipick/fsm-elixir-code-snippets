defmodule Flight.Repo.Migrations.AddBulkInvoiceIdToInvoicesAndTransactions do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:bulk_invoice_id, :integer)
    end

    alter table(:transactions) do
      add(:bulk_invoice_id, :integer)
    end

    create(index(:invoices, [:bulk_invoice_id]))
    create(index(:transactions, [:bulk_invoice_id]))
  end
end

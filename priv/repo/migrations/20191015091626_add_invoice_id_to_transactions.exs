defmodule Flight.Repo.Migrations.AddInvoiceIdToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:invoice_id, references(:invoices, on_delete: :nothing))
    end

    create index(:transactions, [:invoice_id])
  end
end

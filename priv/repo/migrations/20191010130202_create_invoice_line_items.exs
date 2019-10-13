defmodule Flight.Repo.Migrations.CreateInvoiceLineItems do
  use Ecto.Migration

  def change do
    create table(:invoice_line_items) do
      add(:invoice_id, references(:invoices, on_delete: :nothing))
      add(:description, :string)
      add(:rate, :integer)
      add(:quantity, :integer)
      add(:amount, :integer)

      timestamps()
    end

    create(index(:invoice_line_items, [:invoice_id]))
  end
end

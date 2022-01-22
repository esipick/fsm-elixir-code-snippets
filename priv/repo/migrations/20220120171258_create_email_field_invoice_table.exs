defmodule Flight.Repo.Migrations.CreateEmailFieldInvoiceTable do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:payer_email,  :string, default: nil)
    end
  end
end

defmodule Flight.Repo.Migrations.AddPayerNameToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:payer_name, :string)
    end
  end
end

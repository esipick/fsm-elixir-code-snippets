defmodule Flight.Repo.Migrations.AddDemoFlightToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add :demo, :boolean, default: false
    end
  end
end

defmodule Flight.Repo.Migrations.AlterInvoiceAddAircraftsInfo do
  use Ecto.Migration

  def up do
      alter table(:invoices) do
        add :aircraft_info, :map
      end
  end

  def down do
    alter table(:invoices) do
      remove :aircraft_info
    end
  end
end

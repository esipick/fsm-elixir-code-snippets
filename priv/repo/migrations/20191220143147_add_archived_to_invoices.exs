defmodule Flight.Repo.Migrations.AddArchivedToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:archived, :boolean, default: false)
    end
  end
end

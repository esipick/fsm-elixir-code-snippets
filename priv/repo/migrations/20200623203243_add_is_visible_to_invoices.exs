defmodule Flight.Repo.Migrations.AddIsVisibleToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add :is_visible, :boolean, default: true
    end
  end
end

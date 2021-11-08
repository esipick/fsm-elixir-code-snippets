defmodule Flight.Repo.Migrations.AlterTableInvoicesAddIsAdminInvoice do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:is_admin_invoice, :boolean, default: false)
    end
  end
end

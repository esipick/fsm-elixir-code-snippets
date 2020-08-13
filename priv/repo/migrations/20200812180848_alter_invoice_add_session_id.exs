defmodule Flight.Repo.Migrations.AlterInvoiceAddSessionId do
  use Ecto.Migration

  def up do
    alter table(:invoices) do
      add :session_id, :string, null: true
    end
  end

  def down do
    alter table(:invoices) do
      remove :session_id
    end
  end
end

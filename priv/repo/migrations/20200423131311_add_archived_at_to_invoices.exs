defmodule Flight.Repo.Migrations.AddArchivedAtToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:archived_at, :naive_datetime, null: true)
    end
    create(unique_index(:invoices, [:appointment_id, :archived_at]))
  end
end

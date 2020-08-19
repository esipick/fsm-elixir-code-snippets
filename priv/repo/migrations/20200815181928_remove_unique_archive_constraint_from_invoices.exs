defmodule Flight.Repo.Migrations.RemoveUniqueArchiveConstraintFromInvoices do
  use Ecto.Migration

  def up do
    drop(unique_index(:invoices, [:appointment_id, :archived_at]))
  end

  def down do
    create(unique_index(:invoices, [:appointment_id, :archived_at]))
  end
end

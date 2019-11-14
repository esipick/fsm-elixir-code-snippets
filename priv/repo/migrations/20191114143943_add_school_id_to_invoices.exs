defmodule Flight.Repo.Migrations.AddSchoolIdToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:school_id, :integer)
    end
  end
end

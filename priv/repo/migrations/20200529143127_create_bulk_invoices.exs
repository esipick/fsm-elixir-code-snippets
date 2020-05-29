defmodule Flight.Repo.Migrations.CreateBulkInvoices do
  use Ecto.Migration

  def change do
    create table(:bulk_invoices) do
      add(:payment_option, :integer)
      add(:total_amount_due, :integer)
      add(:user_id, references(:users, on_delete: :nothing), null: true)
      add(:school_id, references(:schools, on_delete: :nothing), null: true)

      timestamps()
    end
  end
end

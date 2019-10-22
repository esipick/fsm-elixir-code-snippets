defmodule Flight.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:payment_option, :integer)
      add(:status, :integer, default: 0)
      add(:date, :date)
      add(:total, :integer)
      add(:tax_rate, :float)
      add(:total_tax, :integer)
      add(:total_amount_due, :integer)

      timestamps()
    end

    create(index(:invoices, [:user_id]))
  end
end

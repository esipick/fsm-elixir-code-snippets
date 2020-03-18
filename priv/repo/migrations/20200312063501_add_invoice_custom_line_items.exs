defmodule Flight.Repo.Migrations.AddInvoiceCustomLineItems do
  use Ecto.Migration

  def change do
    create table(:invoice_custom_line_items) do
      add(:school_id, references(:schools, on_delete: :nothing))
      add(:description, :string)
      add(:default_rate, :integer)

      timestamps()
    end

    create(index(:invoice_custom_line_items, [:school_id]))
    create(unique_index(:invoice_custom_line_items, [:description, :school_id]))
  end
end

defmodule Flight.Repo.Migrations.AddTaxableToLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_custom_line_items) do
      add(:taxable, :boolean, default: false)
    end

    alter table(:invoice_line_items) do
      add(:taxable, :boolean, default: false)
    end
  end
end

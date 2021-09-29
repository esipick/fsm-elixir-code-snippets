defmodule Flight.Repo.Migrations.AlterTableInvoiceLineItemsAddCourseId do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:course_id, :integer, null: true)
    end
  end

end

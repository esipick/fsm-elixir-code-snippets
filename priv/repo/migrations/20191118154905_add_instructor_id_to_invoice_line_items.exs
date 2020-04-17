defmodule Flight.Repo.Migrations.AddInstructorIdToInvoiceLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:instructor_user_id, references(:users, on_delete: :nothing), null: true)
    end
  end
end

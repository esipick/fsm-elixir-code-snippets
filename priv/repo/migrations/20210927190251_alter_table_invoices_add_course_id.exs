defmodule Flight.Repo.Migrations.AlterTableInvoicesAddCourseId do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:course_id, :integer, null: true)
    end
  end
end

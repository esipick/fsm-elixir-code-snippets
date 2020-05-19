defmodule Flight.Repo.Migrations.AddCreatorIdToLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add(:creator_id, references(:users, on_delete: :nothing))
    end
  end
end

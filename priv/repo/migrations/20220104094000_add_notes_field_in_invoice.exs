defmodule Flight.Repo.Migrations.AddNotesFieldInInvoice do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:notes,  :text)
    end
  end
end

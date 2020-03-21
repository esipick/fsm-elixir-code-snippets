defmodule Flight.Repo.Migrations.AddHobbsAndTachToInvoiceLineItems do
  use Ecto.Migration

  def change do
    alter table(:invoice_line_items) do
      add :hobbs_start, :integer
      add :hobbs_end, :integer
      add :tach_start, :integer
      add :tach_end, :integer
      add :hobbs_tach_used, :boolean
    end
  end
end

defmodule Flight.Repo.Migrations.AddAppointmentUpdatedAtToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add :appointment_updated_at, :naive_datetime
    end
  end
end

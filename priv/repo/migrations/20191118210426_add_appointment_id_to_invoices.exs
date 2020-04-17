defmodule Flight.Repo.Migrations.AddAppointmentIdToInvoices do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add(:appointment_id, references(:appointments, on_delete: :nothing), null: true)
    end
  end
end

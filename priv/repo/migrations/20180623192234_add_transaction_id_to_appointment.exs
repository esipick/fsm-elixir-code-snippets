defmodule Flight.Repo.Migrations.AddTransactionIdToAppointment do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      add(:transaction_id, references(:transactions, on_delete: :nothing))
    end
  end
end

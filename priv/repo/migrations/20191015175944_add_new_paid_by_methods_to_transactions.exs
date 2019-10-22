defmodule Flight.Repo.Migrations.AddNewPaidByMethodsToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:paid_by_check, :integer)
      add(:paid_by_venmo, :integer)
    end
  end
end

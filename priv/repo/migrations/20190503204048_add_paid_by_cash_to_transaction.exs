defmodule Flight.Repo.Migrations.AddPaidByCashToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:paid_by_cash, :integer)
    end
  end
end

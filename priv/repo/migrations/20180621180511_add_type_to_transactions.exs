defmodule Flight.Repo.Migrations.AddTypeToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:type, :string)
    end
  end
end

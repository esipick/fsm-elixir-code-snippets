defmodule Flight.Repo.Migrations.AddTypeToTransactionLineItem do
  use Ecto.Migration

  def change do
    alter table(:transaction_line_items) do
      add(:type, :string)
    end
  end
end

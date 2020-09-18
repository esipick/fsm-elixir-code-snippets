defmodule Flight.Repo.Migrations.AlterTransactionLineItemAddSalesTax do
  use Ecto.Migration

  def up do
    alter table(:transaction_line_items) do
      add :total_tax, :integer, default: 0
    end
  end

  def up do
    alter table(:transaction_line_items) do
      remove :total_tax
    end
  end
end

defmodule Flight.Repo.Migrations.AddSalesTaxToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:sales_tax, :float)
    end
  end
end

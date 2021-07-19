defmodule Flight.Repo.Migrations.CreateTableInspectionData do
  use Ecto.Migration

    def change do
        InspectionDataType.create_type
        create table(:inspection_data) do
            add :name, :string, size: 50
            add :class_name, :string, size: 100
            add :type, InspectionDataType.type
            add :sort, :integer
            add :t_int, :integer
            add :t_str, :string, size: 200
            add :t_float, :float
            add :t_date, :date
            add :inspection_id, references(:inspections)
        end

        create(index(:inspection_data, [:inspection_id]))
    end
end
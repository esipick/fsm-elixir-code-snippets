defmodule Flight.Repo.Migrations.CreateMaintenance do
  use Ecto.Migration

  def change do
    create table(:maintenance, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string, null: false
      add :description, :string, null: true

      add :tach_hours, :integer, null: true # the event will occur after this much tach hours
      add :no_of_months, :integer, null: true # Or the event will occur after this much calendar days

      add :ref_start_date, :naive_datetime, null: true # if maintenance is on calander months based, it will be the reference date. 
      add :due_date, :naive_datetime, null: true

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end

    create unique_index(:maintenance, :name)
  end
end

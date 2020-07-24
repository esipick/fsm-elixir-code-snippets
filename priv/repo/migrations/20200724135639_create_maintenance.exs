defmodule Flight.Repo.Migrations.CreateMaintenance do
  use Ecto.Migration

  def change do
    create table(:maintenance, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string, null: false
      add :description, :string, null: true

      add :tach_hours, :integer, default: 0 # the event will occur after this much tach hours
      add :no_of_days, :integer, default: 0 # Or the event will occur after this much calendar days
      
      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end

    create index(:maintenance, :name)
  end
end

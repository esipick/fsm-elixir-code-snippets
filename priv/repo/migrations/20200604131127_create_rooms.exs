defmodule Flight.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :capacity, :integer
      add :location, :text
      add :resources, :text
      add :rate_per_hour, :integer
      add :block_rate_per_hour, :integer
      add :archived, :boolean, default: false, null: false

      add :school_id, references(:schools)

      timestamps()
    end

    create(index(:rooms, [:school_id]))
  end
end

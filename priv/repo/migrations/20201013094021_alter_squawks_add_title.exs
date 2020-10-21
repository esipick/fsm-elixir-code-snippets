defmodule Flight.Repo.Migrations.AlterSquawksAddTitle do
  use Ecto.Migration

  def up do
    alter table(:squawks) do
      add(:title, :string, default: "Squawk Issue")
    end
  end

  def down do
    alter table(:squawks) do
      remove(:title)
    end
  end
end

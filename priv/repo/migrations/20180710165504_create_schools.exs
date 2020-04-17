defmodule Flight.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add(:name, :string)

      timestamps()
    end
  end
end

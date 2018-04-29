defmodule Flight.Repo.Migrations.CreateRoles do
  use Ecto.Migration

  def change do
    create table(:roles) do
      add :slug, :text

      timestamps()
    end

  end
end

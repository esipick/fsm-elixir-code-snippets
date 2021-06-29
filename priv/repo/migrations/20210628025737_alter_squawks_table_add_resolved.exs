defmodule Flight.Repo.Migrations.AlterSquawksTableAddResolved do
  use Ecto.Migration

  alter table("squawks") do
    add :resolved, :boolean, default: false
  end

end
defmodule Flight.Repo.Migrations.PopulateSimulatorsName do
  use Ecto.Migration

  def up do
    execute("update aircrafts set name=(model || ' ' || 'Simulator') where simulator=true;")
  end

  def down do
  end
end

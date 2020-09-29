defmodule Flight.Repo.Migrations.UpdateAircraftAddBlocked do
  use Ecto.Migration

  def up do
    alter table(:aircrafts) do
      add(:blocked, :boolean, default: false)
    end
  end

  def down do
    alter table(:aircrafts) do
      remove(:blocked)
    end
  end
end

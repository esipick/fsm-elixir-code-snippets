defmodule Flight.Repo.Migrations.AddArchivedToAircraft do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add(:archived, :boolean, default: false, null: false)
    end
  end
end

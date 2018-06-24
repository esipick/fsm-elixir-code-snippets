defmodule Flight.Repo.Migrations.AddLastHobbsTimeToAircraft do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add(:last_hobbs_time, :integer, null: false, default: 0)
    end
  end
end

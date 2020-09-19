defmodule Flight.Repo.Migrations.AlterUnavailabilityAddRoomsAndSimulator do
  use Ecto.Migration

  def up do
    alter table(:unavailabilities) do
      add(:simulator_id, references(:aircrafts, type: :id, on_delete: :nothing))
      add(:room_id, references(:rooms, type: :id, on_delete: :nothing))
    end
  end

  def down do
    alter table(:unavailabilities) do
      remove(:simulator_id)
      remove(:room_id)
    end
  end
end

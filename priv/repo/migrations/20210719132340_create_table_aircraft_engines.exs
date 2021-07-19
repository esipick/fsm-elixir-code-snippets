defmodule Flight.Repo.Migrations.CreateTableAircraftEngines do
  use Ecto.Migration

  def change do
    EnginePosition.create_type
    create table(:aircarft_engines) do
      add(:engine_make, :string)
      add(:engine_model, :string)
      add(:engine_serial, :string)
      add(:engine_tach_start, :float)
      add(:engine_hobbs_start, :float)
      add(:is_tachometer, :boolean)
      add(:engine_position, EnginePosition.type())

      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))

      timestamps()
    end
  end
end

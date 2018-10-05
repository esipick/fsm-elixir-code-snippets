defmodule Flight.Repo.Migrations.CreateUnavailabilities do
  use Ecto.Migration

  def change do
    create table(:unavailabilities) do
      add(:start_at, :naive_datetime)
      add(:end_at, :naive_datetime)
      add(:type, :string)
      add(:note, :string)
      add(:available, :boolean, default: false, null: false)
      add(:instructor_user_id, references(:users, on_delete: :nothing))
      add(:aircraft_id, references(:aircrafts, on_delete: :nothing))
      add(:school_id, references(:schools, on_delete: :nothing))

      timestamps()
    end

    create(index(:unavailabilities, [:school_id]))
    create(index(:unavailabilities, [:instructor_user_id]))
    create(index(:unavailabilities, [:aircraft_id]))
  end
end

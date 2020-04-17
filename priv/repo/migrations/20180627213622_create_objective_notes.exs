defmodule Flight.Repo.Migrations.CreateObjectiveNotes do
  use Ecto.Migration

  def change do
    create table(:objective_notes) do
      add(:note, :string)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:objective_id, references(:objectives, on_delete: :nothing))

      timestamps()
    end

    create(index(:objective_notes, [:user_id]))
    create(index(:objective_notes, [:objective_id]))
  end
end

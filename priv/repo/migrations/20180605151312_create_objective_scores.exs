defmodule Flight.Repo.Migrations.CreateObjectiveScores do
  use Ecto.Migration

  def change do
    create table(:objective_scores) do
      add(:score, :integer)
      add(:user_id, references(:users, on_delete: :nothing))
      add(:objective_id, references(:objectives, on_delete: :nothing))

      timestamps()
    end

    create(index(:objective_scores, [:user_id]))
    create(index(:objective_scores, [:objective_id]))
  end
end

defmodule Flight.Repo.Migrations.AddSchoolIdToUserData do
  use Ecto.Migration

  def change do
    alter table(:objective_notes) do
      add(:school_id, references(:schools))
    end

    alter table(:objective_scores) do
      add(:school_id, references(:schools))
    end

    create(index(:objective_notes, [:school_id]))
    create(index(:objective_scores, [:school_id]))
  end
end

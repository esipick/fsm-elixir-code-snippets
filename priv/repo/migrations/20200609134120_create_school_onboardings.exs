defmodule Flight.Repo.Migrations.CreateSchoolOnboardings do
  use Ecto.Migration

  def change do
    create table(:school_onboardings) do
      add :current_step, :integer, default: 0
      add :completed, :boolean, default: false
      add :school_id, references(:schools)

      timestamps()
    end

    create(index(:school_onboardings, [:school_id]))
  end
end

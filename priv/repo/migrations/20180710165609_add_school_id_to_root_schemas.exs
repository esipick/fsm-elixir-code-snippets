defmodule Flight.Repo.Migrations.AddSchoolIdToRootSchemas do
  use Ecto.Migration

  def change do
    alter table(:aircrafts) do
      add(:school_id, references(:schools))
    end

    alter table(:appointments) do
      add(:school_id, references(:schools))
    end

    alter table(:invitations) do
      add(:school_id, references(:schools))
    end

    alter table(:transactions) do
      add(:school_id, references(:schools))
    end

    alter table(:users) do
      add(:school_id, references(:schools))
    end

    create(index(:aircrafts, [:school_id]))
    create(index(:appointments, [:school_id]))
    create(index(:invitations, [:school_id]))
    create(index(:transactions, [:school_id]))
    create(index(:users, [:school_id]))
  end
end

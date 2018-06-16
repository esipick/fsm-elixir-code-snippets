defmodule Flight.Repo.Migrations.CreateSyllabuses do
  use Ecto.Migration

  def change do
    create table(:syllabuses) do
      add :lesson_id, references(:lessons, on_delete: :nothing)

      timestamps()
    end

    create index(:syllabuses, [:lesson_id])
  end
end

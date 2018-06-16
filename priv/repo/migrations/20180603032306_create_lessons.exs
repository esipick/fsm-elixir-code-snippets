defmodule Flight.Repo.Migrations.CreateLessons do
  use Ecto.Migration

  def change do
    create table(:lessons) do
      add :name, :string
      add :course_id, references(:courses, on_delete: :nothing)

      timestamps()
    end

    create index(:lessons, [:course_id])
  end
end

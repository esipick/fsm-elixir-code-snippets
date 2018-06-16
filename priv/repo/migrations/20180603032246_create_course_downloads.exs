defmodule Flight.Repo.Migrations.CreateCourseDownloads do
  use Ecto.Migration

  def change do
    create table(:course_downloads) do
      add :name, :string
      add :course_id, references(:courses, on_delete: :nothing)

      timestamps()
    end

    create index(:course_downloads, [:course_id])
  end
end

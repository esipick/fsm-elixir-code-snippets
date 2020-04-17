defmodule Flight.Repo.Migrations.CreateLessonCategories do
  use Ecto.Migration

  def change do
    create table(:lesson_categories) do
      add(:name, :string)
      add(:lesson_id, references(:lessons, on_delete: :nothing))

      timestamps()
    end

    create(index(:lesson_categories, [:lesson_id]))
  end
end

defmodule Flight.Repo.Migrations.CreateObjectives do
  use Ecto.Migration

  def change do
    create table(:objectives) do
      add(:name, :string)
      add(:lesson_category_id, references(:lesson_categories, on_delete: :nothing))

      timestamps()
    end

    create(index(:objectives, [:lesson_category_id]))
  end
end

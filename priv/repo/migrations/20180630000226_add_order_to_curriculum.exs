defmodule Flight.Repo.Migrations.AddOrderToCurriculum do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      add(:order, :integer, default: 0, null: false)
    end

    alter table(:course_downloads) do
      add(:order, :integer, default: 0, null: false)
    end

    alter table(:lessons) do
      add(:order, :integer, default: 0, null: false)
    end

    alter table(:lesson_categories) do
      add(:order, :integer, default: 0, null: false)
    end

    alter table(:objectives) do
      add(:order, :integer, default: 0, null: false)
    end
  end
end

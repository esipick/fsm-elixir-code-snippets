defmodule Flight.Repo.Migrations.AddSyllabusUrlToLesson do
  use Ecto.Migration

  def change do
    alter table(:lessons) do
      add(:syllabus_url, :string)
    end
  end
end

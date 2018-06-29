defmodule Flight.Repo.Migrations.AddVersionToCourseDownloadAndLessonSyllabus do
  use Ecto.Migration

  def change do
    alter table(:course_downloads) do
      add(:version, :integer, default: 1)
      add(:url, :string)
    end

    alter table(:lessons) do
      add(:syllabus_version, :integer, default: 1)
      add(:syllabus_url, :string)
    end
  end
end

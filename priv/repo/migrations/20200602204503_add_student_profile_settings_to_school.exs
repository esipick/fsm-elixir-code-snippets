defmodule Flight.Repo.Migrations.AddStudentProfileSettingsToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:show_student_accounts_summary, :boolean, default: true)
      add(:show_student_flight_hours, :boolean, default: true)
    end
  end
end

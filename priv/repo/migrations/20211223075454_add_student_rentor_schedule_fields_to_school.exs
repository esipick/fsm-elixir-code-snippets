defmodule Flight.Repo.Migrations.AddStudentRentorScheduleFieldsToSchool do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:student_schedule, :boolean, default: true)
      add(:renter_schedule, :boolean, default: true)
    end
  end
end

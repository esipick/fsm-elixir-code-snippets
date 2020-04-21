defmodule Flight.Repo.Migrations.AddInstructorToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:main_instructor_id, references(:users, on_delete: :nothing), null: true)
    end
  end
end

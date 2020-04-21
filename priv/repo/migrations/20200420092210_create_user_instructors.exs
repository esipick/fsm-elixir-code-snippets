defmodule Flight.Repo.Migrations.CreateUserInstructors do
  use Ecto.Migration

  def change do
    create table(:user_instructors) do
      add(:user_id, references(:users, on_delete: :nothing))
      add(:instructor_id, references(:users, on_delete: :nothing))
    end

    create(index(:user_instructors, [:user_id]))
    create(index(:user_instructors, [:instructor_id]))

    create(
      unique_index(:user_instructors, [:user_id, :instructor_id],
        name: :user_id_instructor_id_unique_index
      )
    )
  end
end

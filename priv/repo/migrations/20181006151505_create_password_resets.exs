defmodule Flight.Repo.Migrations.CreatePasswordResets do
  use Ecto.Migration

  def change do
    create table(:password_resets) do
      add(:token, :text)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:password_resets, [:user_id]))
  end
end

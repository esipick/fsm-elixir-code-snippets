defmodule Flight.Repo.Migrations.AddDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add(:expires_at, :date)
      add(:file, :string)
      add(:user_id, references(:users, on_delete: :nothing))

      timestamps()
    end

    create(index(:documents, [:user_id]))
  end
end

defmodule Flight.Repo.Migrations.CreateChecklist do
  use Ecto.Migration

  def change do
    create table(:checklist, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:name, :string, null: false)
      add(:description, :string, null: true)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

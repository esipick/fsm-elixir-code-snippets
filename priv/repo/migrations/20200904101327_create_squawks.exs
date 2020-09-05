defmodule Flight.Repo.Migrations.CreateSquawks do
  use Ecto.Migration

  def change do
    create table(:squawks, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:description, :string, null: false)
      add(:severity, :integer, default: 0)
      add(:reported_at, :naive_datetime, default: fragment("now()"))
      add(:resolved_at, :naive_datetime)

      add(:aircraft_id, references(:aircrafts, type: :id, on_delete: :delete_all))
      add(:reported_by_id, references(:users, type: :id, on_delete: :nothing))
      add(:created_by_id, references(:users, type: :id, on_delete: :nothing))
      add(:school_id, references(:schools, type: :id, on_delete: :delete_all))

      add(:notify_roles, {:array, :string}, null: true)
      add(:notes, :string, null: true)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

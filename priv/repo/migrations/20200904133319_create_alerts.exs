defmodule Flight.Repo.Migrations.CreateAlerts do
  use Ecto.Migration

  def change do
    create table(:alerts) do
      add(:code, :string, null: false)
      add(:title, :string, null: false)
      add(:description, :string, null: false)

      add(:priority, :integer, null: false)

      add(:receiver_id, references(:users, type: :id, on_delete: :nothing))
      add(:sender_id, references(:users, type: :id, on_delete: :nothing))
      add(:school_id, references(:schools, type: :id, on_delete: :nothing))

      add(:additional_info, :map, null: true)

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

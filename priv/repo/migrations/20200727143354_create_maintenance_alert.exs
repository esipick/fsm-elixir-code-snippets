defmodule Flight.Repo.Migrations.CreateMaintenanceAlert do
  use Ecto.Migration

  def change do
      create table(:maintenance_alerts, primary_key: false) do
        add(:id, :binary_id, primary_key: true)
        add(:name, :string, null: false)
        add(:description, :string, null: false)

        add(:send_to_roles, {:array, :string}, null: false)

        add(:maintenance_id, references(:maintenance, type: :binary_id, on_delete: :delete_all))

        timestamps([inserted_at: :created_at, default: fragment("now()")])
      end
  end
end

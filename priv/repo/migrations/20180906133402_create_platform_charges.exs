defmodule Flight.Repo.Migrations.CreatePlatformCharges do
  use Ecto.Migration

  def change do
    create table(:platform_charges) do
      add :amount, :integer
      add :type, :string
      add :stripe_charge_id, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:platform_charges, [:user_id])
  end
end

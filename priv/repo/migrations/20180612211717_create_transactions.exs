defmodule Flight.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :total, :integer
      add :paid_by_balance, :integer
      add :paid_by_charge, :integer
      add :stripe_charge_id, :string
      add :state, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :creator_user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:transactions, [:user_id])
    create index(:transactions, [:creator_user_id])
  end
end

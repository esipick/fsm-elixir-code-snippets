defmodule Flight.Repo.Migrations.CreateStripeAccounts do
  use Ecto.Migration

  def change do
    create table(:stripe_accounts) do
      add(:stripe_account_id, :string)
      add(:details_submitted, :boolean, default: false, null: false)
      add(:charges_enabled, :boolean, default: false, null: false)
      add(:payouts_enabled, :boolean, default: false, null: false)
      add(:school_id, references(:schools))

      timestamps()
    end

    create(index(:stripe_accounts, [:school_id]))
  end
end

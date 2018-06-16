defmodule Flight.Repo.Migrations.AddStripeCustomerIdToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:stripe_customer_id, :text)
    end

    create(unique_index(:users, [:stripe_customer_id]))
  end
end

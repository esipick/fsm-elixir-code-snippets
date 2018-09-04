defmodule Flight.Repo.Migrations.AddStripeAccountSourceToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:stripe_account_source, :string, default: "connected")
    end
  end
end

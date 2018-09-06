defmodule Flight.Repo.Migrations.RemoveStripeAccountSourceFromUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove(:stripe_account_source)
    end
  end
end

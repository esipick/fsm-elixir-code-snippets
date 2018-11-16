defmodule Flight.Repo.Migrations.AddCustomCardValuesToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:first_name, :text)
      add(:last_name, :text)
      add(:email, :text)
    end
  end
end

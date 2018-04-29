defmodule Flight.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:email, :text, null: false)
      add(:first_name, :text)
      add(:last_name, :text)
      add(:password_hash, :text)
      add(:balance, :integer)

      timestamps()
    end

    create(unique_index(:users, [:email]))
  end
end

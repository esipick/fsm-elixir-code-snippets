defmodule Flight.Repo.Migrations.AddPasswordTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:password_token, :string)
    end
  end
end

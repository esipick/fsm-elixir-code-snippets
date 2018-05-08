defmodule Flight.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add(:email, :string)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:token, :string)
      add(:role_id, references(:roles, on_delete: :nothing))

      timestamps()
    end

    create(unique_index(:invitations, [:email]))
    create(unique_index(:invitations, [:token]))
  end
end

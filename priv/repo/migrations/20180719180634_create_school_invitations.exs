defmodule Flight.Repo.Migrations.CreateSchoolInvitations do
  use Ecto.Migration

  def change do
    create table(:school_invitations) do
      add(:email, :string)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:token, :string)
      add(:accepted_at, :naive_datetime)

      timestamps()
    end

    create(unique_index(:school_invitations, [:token]))
  end
end

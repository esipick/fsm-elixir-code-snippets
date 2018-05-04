defmodule Flight.Repo.Migrations.CreateUserFlyerCertificates do
  use Ecto.Migration

  def change do
    create table(:user_flyer_certificates) do
      add :user_id, references(:users, on_delete: :nothing)
      add :flyer_certificate_id, references(:flyer_certificates, on_delete: :nothing)

      timestamps()
    end

    create index(:user_flyer_certificates, [:user_id])
    create index(:user_flyer_certificates, [:flyer_certificate_id])
  end
end

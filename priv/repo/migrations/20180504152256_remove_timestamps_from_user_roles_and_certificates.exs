defmodule Flight.Repo.Migrations.RemoveTimestampsFromUserRolesAndCertificates do
  use Ecto.Migration

  def change do
    alter table(:user_roles) do
      remove(:inserted_at)
      remove(:updated_at)
    end

    alter table(:user_flyer_certificates) do
      remove(:inserted_at)
      remove(:updated_at)
    end
  end
end

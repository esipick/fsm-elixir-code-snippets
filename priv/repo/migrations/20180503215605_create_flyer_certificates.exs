defmodule Flight.Repo.Migrations.CreateFlyerCertificates do
  use Ecto.Migration

  def change do
    create table(:flyer_certificates) do
      add(:slug, :string)

      timestamps()
    end
  end
end

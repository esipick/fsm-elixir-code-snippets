defmodule Flight.Repo.Migrations.CreateZipCode do
  use Ecto.Migration

  def change do
    create table(:zip_codes, primary_key: false) do
      add :zip_code, :string, primary_key: true

      add :city, :string, null: false
      add :state, :string, null: false
      add :state_abbrv, :string, null: false 
      add :country, :string, null: false

      timestamps([inserted_at: :created_at, default: fragment("now()")])
    end
  end
end

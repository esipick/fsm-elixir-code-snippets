defmodule Flight.Repo.Migrations.AddDetailsToSchools do
  use Ecto.Migration

  def change do
    alter table(:schools) do
      add(:address_1, :string)
      add(:city, :string)
      add(:state, :string)
      add(:zipcode, :string)
      add(:phone_number, :string)
      add(:email, :string)
      add(:website, :string)
      add(:contact_first_name, :string)
      add(:contact_last_name, :string)
      add(:contact_phone_number, :string)
    end
  end
end

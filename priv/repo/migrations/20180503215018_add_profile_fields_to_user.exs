defmodule Flight.Repo.Migrations.AddProfileFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:phone_number, :string)
      add(:address_1, :string)
      add(:city, :string)
      add(:state, :string)
      add(:zipcode, :string)
      add(:flight_training_number, :string)
      add(:medical_rating, :integer)
      add(:medical_expires_at, :date)
      add(:certificate_number, :string)
      add(:billing_rate, :integer)
      add(:pay_rate, :integer)
      add(:awards, :string)
    end
  end
end

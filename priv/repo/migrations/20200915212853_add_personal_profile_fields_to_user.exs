defmodule Flight.Repo.Migrations.AddPersonalProfileFieldsToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:date_of_birth, :date)
      add(:gender, :string)
      add(:emergency_contact_no, :string)
      add(:emergency_phone_no, :string)
      add(:d_license_no, :string)
      add(:d_license_expires_at, :date)
      add(:d_license_country, :string)
      add(:d_license_state, :string)
      add(:passport_no, :string)
      add(:passport_expires_at, :date)
      add(:passport_country, :string)
      add(:passport_issuer_name, :string)
      add(:last_faa_flight_review_at, :date)
      add(:renter_policy_no, :string)
      add(:renter_insurance_expires_at, :date)
    end
  end
end

defmodule Flight.Repo.Migrations.ChangeVarcharToText do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      modify(:note, :text)
    end

    alter table(:aircrafts) do
      modify(:make, :text)
      modify(:model, :text)
      modify(:tail_number, :text)
      modify(:serial_number, :text)
      modify(:equipment, :text)
    end

    alter table(:course_downloads) do
      modify(:name, :text)
      modify(:url, :text)
    end

    alter table(:courses) do
      modify(:name, :text)
    end

    alter table(:flyer_certificates) do
      modify(:slug, :text)
    end

    alter table(:inspections) do
      modify(:type, :text)
      modify(:name, :text)
    end

    alter table(:invitations) do
      modify(:email, :text)
      modify(:first_name, :text)
      modify(:last_name, :text)
      modify(:token, :text)
    end

    alter table(:school_invitations) do
      modify(:email, :text)
      modify(:first_name, :text)
      modify(:last_name, :text)
      modify(:token, :text)
    end

    alter table(:lesson_categories) do
      modify(:name, :text)
    end

    alter table(:lessons) do
      modify(:name, :text)
      modify(:syllabus_url, :text)
    end

    alter table(:objective_notes) do
      modify(:note, :text)
    end

    alter table(:objectives) do
      modify(:name, :text)
    end

    alter table(:platform_charges) do
      modify(:type, :text)
      modify(:stripe_charge_id, :text)
    end

    alter table(:push_tokens) do
      modify(:endpoint_arn, :text)
      modify(:token, :text)
      modify(:platform, :text)
    end

    alter table(:schools) do
      modify(:name, :text)
      modify(:contact_email, :text)
      modify(:address_1, :text)
      modify(:city, :text)
      modify(:state, :text)
      modify(:zipcode, :text)
      modify(:phone_number, :text)
      modify(:email, :text)
      modify(:website, :text)
      modify(:contact_first_name, :text)
      modify(:contact_last_name, :text)
      modify(:contact_phone_number, :text)
      modify(:timezone, :text)
    end

    alter table(:stripe_accounts) do
      modify(:stripe_account_id, :text)
    end

    alter table(:transaction_line_items) do
      modify(:description, :text)
      modify(:type, :text)
    end

    alter table(:transactions) do
      modify(:stripe_charge_id, :text)
      modify(:state, :text)
      modify(:type, :text)
    end

    alter table(:unavailabilities) do
      modify(:type, :text)
      modify(:note, :text)
    end

    alter table(:users) do
      modify(:address_1, :text)
      modify(:city, :text)
      modify(:state, :text)
      modify(:zipcode, :text)
      modify(:phone_number, :text)
      modify(:flight_training_number, :text)
      modify(:certificate_number, :text)
      modify(:awards, :text)
    end
  end
end

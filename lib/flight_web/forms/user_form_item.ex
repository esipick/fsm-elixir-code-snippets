defmodule FlightWeb.Form.Option do
  defstruct [:name, :value]
end

defmodule FlightWeb.Form.Item do
  defstruct [:key, :name, :order, :type, :value, options: []]
end

defmodule FlightWeb.UserForm do
  alias FlightWeb.Form.{Item, Option}

  def item(user, :first_name) do
    %Item{key: :first_name, name: "First Name", type: :string, value: user.first_name, order: 1}
  end

  def item(user, :last_name) do
    %Item{key: :last_name, name: "Last Name", type: :string, value: user.last_name, order: 5}
  end

  def item(user, :email) do
    %Item{key: :email, name: "Email", type: :string, value: user.email, order: 10}
  end

  def item(user, :phone_number) do
    %Item{key: :phone_number, name: "Phone #", type: :string, value: user.phone_number, order: 15}
  end

  def item(user, :address_1) do
    %Item{key: :address_1, name: "Address", type: :string, value: user.address_1, order: 20}
  end

  def item(user, :city) do
    %Item{key: :city, name: "City", type: :string, value: user.city, order: 25}
  end

  def item(user, :state) do
    %Item{key: :state, name: "State", type: :string, value: user.state, order: 30}
  end

  def item(user, :zipcode) do
    %Item{key: :zipcode, name: "Zipcode", type: :string, value: user.zipcode, order: 35}
  end

  def item(user, :flight_training_number) do
    %Item{
      key: :flight_training_number,
      name: "FTN",
      type: :string,
      value: user.flight_training_number,
      order: 40
    }
  end

  def item(user, :certificate_number) do
    %Item{
      key: :certificate_number,
      name: "Certificate #",
      type: :string,
      value: user.certificate_number,
      order: 45
    }
  end

  def item(user, :awards) do
    %Item{key: :awards, name: "Awards", type: :string, value: user.awards, order: 50}
  end

  def item(user, :medical_rating) do
    %Item{
      key: :medical_rating,
      name: "Medical Approval",
      type: :enumeration,
      value: %Option{
        name: human_readable_medical_rating(user.medical_rating),
        value: "#{user.medical_rating}"
      },
      options:
        0..3 |> Enum.map(&%Option{name: human_readable_medical_rating(&1), value: "#{&1}"}),
      order: 55
    }
  end

  def item(user, :medical_expires_at) do
    %Item{
      key: :medical_expires_at,
      name: "Medical Expiration",
      type: :date,
      value: user.medical_expires_at,
      order: 60
    }
  end

  def item(user, :flyer_certificates) do
    user = Flight.Repo.preload(user, :flyer_certificates)

    %Item{
      key: :flyer_certificates,
      name: "Certificates",
      type: :multiselect,
      value:
        Enum.map(user.flyer_certificates, &%Option{name: String.upcase(&1.slug), value: &1.slug}),
      options:
        Flight.Repo.all(Flight.Accounts.FlyerCertificate)
        |> Enum.map(&%Option{name: String.upcase(&1.slug), value: &1.slug}),
      order: 65
    }
  end

  def item(user, :inserted_at) do
    %Item{
      key: :inserted_at,
      name: "Registration date",
      type: :date,
      value: user.inserted_at,
      order: 70
    }
  end

  def item(user, :passport_expires_at) do
    %Item{
      key: :passport_expires_at,
      name: "Passport Expiration",
      type: :date,
      value: user.passport_expires_at,
      order: 75
    }
  end

  def item(user, :d_license_expires_at) do
    %Item{
      key: :d_license_expires_at,
      name: "License Expiration",
      type: :date,
      value: user.d_license_expires_at,
      order: 80
    }
  end

  def item(user, :renter_policy_no) do
    %Item{
      key: :renter_policy_no,
      name: "Renter Policy #",
      type: :string,
      value: user.renter_policy_no,
      order: 85
    }
  end

  def item(user, :date_of_birth) do
    %Item{
      key: :date_of_birth,
      name: "Date of Birth",
      type: :date,
      value: user.date_of_birth,
      order: 90
    }
  end

  def item(user, :passport_country) do
    %Item{
      key: :passport_country,
      name: "Passport Country",
      type: :string,
      value: user.passport_country,
      order: 95
    }
  end

  def item(user, :passport_issuer_name) do
    %Item{
      key: :passport_issuer_name,
      name: "Passport Issuer",
      type: :string,
      value: user.passport_issuer_name,
      order: 100
    }
  end

  def item(user, :last_faa_flight_review_at) do
    %Item{
      key: :last_faa_flight_review_at,
      name: "Last Faa Flight Review",
      type: :date,
      value: user.last_faa_flight_review_at,
      order: 105
    }
  end

  def item(user, :renter_insurance_expires_at) do
    %Item{
      key: :renter_insurance_expires_at,
      name: "Renter Insurance Expiration",
      type: :date,
      value: user.renter_insurance_expires_at,
      order: 110
    }
  end

  def item(user, :passport_no) do
    %Item{
      key: :passport_no,
      name: "Passport #",
      type: :string,
      value: user.passport_no,
      order: 115
    }
  end

  def item(user, :d_license_no) do
    %Item{
      key: :d_license_no,
      name: "Driving License #",
      type: :string,
      value: user.d_license_no,
      order: 120
    }
  end

  def item(user, :d_license_country) do
    %Item{
    key: :d_license_country,
    name: "Driving License Country",
    type: :string,
    value: user.d_license_country,
    order: 125
    }
  end

  def item(user, :gender) do
    %Item{
    key: :gender,
    name: "Gender",
    type: :string,
    value: user.gender,
    order: 130
    }
  end

  def item(user, :emergency_contact_no) do
    %Item{
      key: :emergency_contact_no,
      name: "Emergency Contact #",
      type: :string,
      value: user.emergency_contact_no,
      order: 135
    }
  end

  def item(user, :d_license_state) do
    %Item{
      key: :d_license_state,
      name: "Driving License State",
      type: :string,
      value: user.d_license_state,
      order: 140
    }
  end

  def human_readable_medical_rating(nil), do: nil

  def human_readable_medical_rating(medical_rating) when is_binary(medical_rating) do
    human_readable_medical_rating(String.to_integer(medical_rating))
  end

  def human_readable_medical_rating(medical_rating) when is_integer(medical_rating) do
    case medical_rating do
      0 -> "None"
      1 -> "1st Class"
      2 -> "2nd Class"
      3 -> "3rd Class"
    end
  end
end

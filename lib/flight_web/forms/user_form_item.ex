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
      name: "Medical Rating",
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

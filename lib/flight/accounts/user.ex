defmodule Flight.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:balance, :integer)
    field(:phone_number, :string)
    field(:address_1, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zipcode, :string)
    field(:flight_training_number, :string)
    field(:medical_rating, :string)
    field(:medical_expires_at, Flight.Date)
    field(:certificate_number, :string)
    field(:billing_rate, :integer, default: 75)
    field(:pay_rate, :integer, default: 50)
    field(:awards, :string)
    many_to_many(:roles, Flight.Accounts.Role, join_through: "user_roles", on_replace: :delete)

    many_to_many(
      :flyer_certificates,
      Flight.Accounts.FlyerCertificate,
      join_through: "user_flyer_certificates",
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :first_name, :last_name, :password, :balance])
    |> validate_required([:email, :first_name, :last_name, :balance])
    |> validate_password(:password)
    |> put_pass_hash()
    |> validate_required([:password_hash])
  end

  def profile_changeset(user, attrs, roles, flyer_certificates) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
      :balance,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode,
      :flight_training_number,
      :medical_rating,
      :medical_expires_at,
      :certificate_number,
      :billing_rate,
      :pay_rate,
      :awards
    ])
    |> validate_required([:email, :first_name, :last_name, :balance])
    |> validate_password(:password)
    |> put_assoc(:roles, roles)
    |> put_assoc(:flyer_certificates, flyer_certificates)
    |> validate_length(:roles, min: 1)
    |> validate_format(
      :phone_number,
      ~r/^\(?([0-9]{3})\)?[-.●]?([0-9]{3})[-.●]?([0-9]{4})$/,
      message: "must be in the format: 555-555-5555"
    )
  end

  def validate_password(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, password ->
      case valid_password?(password) do
        {:ok, _} -> []
        {:error, msg} -> [{field, options[:message] || msg}]
      end
    end)
  end

  def human_readable_medical_approval()

  defp valid_password?(password) when byte_size(password) > 7 do
    {:ok, password}
  end

  defp valid_password?(_), do: {:error, "The password is too short"}

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Comeonin.Bcrypt.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end

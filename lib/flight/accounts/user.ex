defmodule Flight.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:balance, :integer, default: 0)
    field(:phone_number, :string)
    field(:address_1, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zipcode, :string)
    field(:flight_training_number, :string)
    field(:medical_rating, :integer, default: 0)
    field(:medical_expires_at, Flight.Date)
    field(:certificate_number, :string)
    field(:billing_rate, Flight.DollarCents, default: 7500)
    field(:pay_rate, Flight.DollarCents, default: 5000)
    field(:awards, :string)
    field(:archived, :boolean, default: false)
    field(:stripe_customer_id, :string)
    belongs_to(:school, Flight.Accounts.School)
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
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode,
      :school_id
    ])
    |> validate_required([
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :password,
      :school_id
    ])
    |> base_validations()
    |> validate_password(:password)
    |> put_pass_hash()
  end

  def initial_user_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
      :phone_number
    ])
    |> validate_required([
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :password
    ])
    |> base_validations()
    |> validate_password(:password)
    |> put_pass_hash()
  end

  def __test_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
      :phone_number,
      :balance,
      :stripe_customer_id
    ])
    |> validate_required([
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :password,
      :balance,
      :school_id
    ])
    |> base_validations()
    |> validate_password(:password)
    |> put_pass_hash()
  end

  def stripe_customer_changeset(user, attrs) do
    user
    |> cast(attrs, [:stripe_customer_id])
    |> validate_required([:stripe_customer_id])
  end

  def archive_changeset(user, attrs) do
    user
    |> cast(attrs, [:archived])
  end

  def api_update_changeset(user, attrs, _roles, flyer_certificates) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode,
      :flight_training_number,
      :medical_rating,
      :medical_expires_at,
      :certificate_number,
      :awards
    ])
    |> base_validations(nil, flyer_certificates)
  end

  def admin_update_changeset(user, attrs, roles, flyer_certificates) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :password,
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
    |> base_validations(roles, flyer_certificates)
  end

  def student_accessible_fields() do
    [
      :email,
      :first_name,
      :last_name,
      :password,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode
    ]
  end

  def student_update_changeset(user, attrs) do
    user
    |> cast(attrs, student_accessible_fields())
    |> base_validations()
    |> put_pass_hash()
  end

  def update_password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_password(:password)
    |> put_pass_hash()
  end

  def base_validations(changeset, roles \\ nil, flyer_certificates \\ nil) do
    changeset
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> validate_required([:email, :first_name, :last_name])
    |> unique_constraint(:email)
    |> trim_email()
    |> validate_length(:roles, min: 1)
    |> validate_password(:password)
    |> validate_format(
      :phone_number,
      Flight.Format.phone_number_regex(),
      message: "must be in the format: 555-555-5555"
    )
    |> normalize_phone_number()
    |> Pipe.pass_unless(roles, &put_assoc(&1, :roles, roles))
    |> Pipe.pass_unless(
      flyer_certificates,
      &put_assoc(&1, :flyer_certificates, flyer_certificates)
    )
  end

  def balance_changeset(user, attrs) do
    user
    |> cast(attrs, [:balance])
    |> validate_required([:balance])
  end

  def trim_email(changeset) do
    email = get_field(changeset, :email)

    if is_binary(email) do
      email =
        email
        |> String.replace(" ", "")
        |> String.downcase()

      put_change(changeset, :email, email)
    else
      changeset
    end
  end

  def validate_password(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, password ->
      case valid_password?(password) do
        {:ok, _} -> []
        {:error, msg} -> [{field, options[:message] || msg}]
      end
    end)
  end

  def normalize_phone_number(changeset) do
    phone_number = get_field(changeset, :phone_number)

    if changeset.valid? && is_binary(phone_number) do
      case Flight.Format.normalize_phone_number(phone_number) do
        {:ok, number} ->
          put_change(changeset, :phone_number, number)

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  def full_name(user) do
    "#{user.first_name} #{user.last_name}"
  end

  defp valid_password?(password) when byte_size(password) > 5 do
    {:ok, password}
  end

  defp valid_password?(_), do: {:error, "The password is too short"}

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> change(Comeonin.Bcrypt.add_hash(password))
    |> delete_change(:password)
  end

  defp put_pass_hash(changeset), do: changeset
end

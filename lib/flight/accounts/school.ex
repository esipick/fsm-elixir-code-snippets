defmodule Flight.Accounts.School do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schools" do
    field(:name, :string)
    field(:address_1, :string)
    field(:city, :string)
    field(:state, :string)
    field(:zipcode, :string)
    field(:phone_number, :string)
    field(:email, :string)
    field(:website, :string)
    field(:contact_first_name, :string)
    field(:contact_last_name, :string)
    field(:contact_phone_number, :string)
    field(:contact_email, :string)
    field(:timezone, :string)
    field(:sales_tax, :float)
    field(:archived, :boolean, default: false)
    has_one(:stripe_account, Flight.Accounts.StripeAccount)

    timestamps()
  end

  @doc false
  def create_changeset(school, attrs) do
    school
    |> cast(attrs, [
      :name,
      :contact_email,
      :contact_first_name,
      :contact_last_name,
      :timezone,
      :contact_phone_number
    ])
    |> base_validations()
  end

  def archive_changeset(user, attrs) do
    user
    |> cast(attrs, [:archived])
  end

  def admin_changeset(school, attrs) do
    school
    |> cast(attrs, [
      :name,
      :address_1,
      :city,
      :state,
      :zipcode,
      :phone_number,
      :email,
      :website,
      :contact_first_name,
      :contact_last_name,
      :contact_phone_number,
      :timezone,
      :contact_email,
      :sales_tax
    ])
    |> base_validations()
  end

  def base_validations(changeset) do
    changeset
    |> validate_required([
      :name,
      :timezone,
      :contact_email,
      :contact_phone_number,
      :contact_first_name,
      :contact_last_name
    ])
    |> validate_format(
      :phone_number,
      Flight.Format.phone_number_regex(),
      message: "must be in the format: 555-555-5555"
    )
    |> normalize_phone_number(:phone_number)
    |> validate_format(
      :contact_phone_number,
      Flight.Format.phone_number_regex(),
      message: "must be in the format: 555-555-5555"
    )
    |> validate_format(
      :zipcode,
      Flight.Format.zipcode_regex(),
      message: "must contain only numbers"
    )
    |> validate_format(
      :email,
      Flight.Format.email_regex(),
      message: "must be in a valid format"
    )
    |> validate_format(
      :contact_email,
      Flight.Format.email_regex(),
      message: "must be in a valid format"
    )
    |> normalize_phone_number(:contact_phone_number)
    |> validate_inclusion(:timezone, valid_timezones())
    |> validate_number(:sales_tax, greater_than_or_equal_to: 0, less_than: 100)
  end

  def normalize_phone_number(changeset, field) do
    phone_number = get_field(changeset, field)

    if changeset.valid? && is_binary(phone_number) do
      case Flight.Format.normalize_phone_number(phone_number) do
        {:ok, number} ->
          put_change(changeset, field, number)

        _ ->
          changeset
      end
    else
      changeset
    end
  end

  def valid_timezones() do
    Tzdata.zone_lists_grouped()[:northamerica]
    |> Enum.filter(&String.starts_with?(&1, "America"))
  end
end

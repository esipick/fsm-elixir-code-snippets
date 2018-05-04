defmodule FlightWeb.Admin.UserView do
  use FlightWeb, :view

  alias Flight.Accounts

  def has_billing?(user) do
    Accounts.has_any_role?(user, ["renter", "instructor", "student"])
  end

  def has_appointments?(user) do
    Accounts.has_any_role?(user, ["renter", "instructor", "student"])
  end

  def has_cirriculum?(user) do
    Accounts.has_any_role?(user, ["student"])
  end

  def has_pay_rates?(user) do
    Accounts.has_any_role?(user, ["instructor"])
  end

  def has_teaching_info?(user) do
    Accounts.has_any_role?(user, ["instructor"])
  end

  def has_address?(user) do
    Accounts.has_any_role?(user, ["instructor", "student", "renter"])
  end

  def has_medical?(user) do
    Accounts.has_any_role?(user, ["instructor", "student"])
  end

  def medical_approval_inputs() do
    0..3
    |> Enum.map(fn medical_rating ->
      {human_readable_medical_rating(medical_rating), medical_rating}
    end)
  end

  def role_inputs() do
    Flight.Accounts.Role.available_role_slugs()
    |> Enum.map(fn role_slug ->
      {String.capitalize(role_slug), role_slug}
    end)
  end

  def user_has_role?(user, role_slug) do
    Accounts.has_role?(user, role_slug)
  end

  def user_has_flyer_certificate?(user, cert_slug) do
    Accounts.has_flyer_certificate?(user, cert_slug)
  end

  def format_date(date) when is_binary(date), do: date
  def format_date(nil), do: ""

  def format_date(date) do
    Flight.Date.format(date)
  end

  def flyer_certificate_inputs() do
    Flight.Accounts.flyer_certificates()
    |> Enum.map(&{String.upcase(&1.slug), &1.slug})
  end

  def human_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn _, _, {message, _} ->
      message
    end)
    |> Enum.reduce([], fn {key, message_list}, acc ->
      Enum.map(message_list, fn message ->
        "#{Phoenix.Naming.humanize(human_key_transform(key))} #{message}"
      end) ++ acc
    end)
  end

  def human_key_transform(key) do
    case key do
      :medical_expires_at -> :medical_expiration
      other -> other
    end
  end

  def human_flyer_certificates(flyer_certificates) do
    result =
      flyer_certificates
      |> Enum.map(&String.upcase(&1.slug))
      |> Enum.join(", ")

    if result == "" do
      "None"
    else
      result
    end
  end

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

  def human_role(role_slug) do
    String.capitalize(role_slug)
  end
end

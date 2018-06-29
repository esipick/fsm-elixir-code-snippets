defmodule FlightWeb.Admin.UserView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

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

  def should_display_address?(user) do
    user.address_1 != nil
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

  def currency(amount) do
    CurrencyFormatter.format(amount, "USD")
  end

  def display_date(date, :short) do
    Timex.format!(date, "%B %-d, %Y", :strftime)
  end

  def display_date(date, :long) do
    Timex.format!(date, "%A %b %-d, %Y", :strftime)
  end

  def display_time(date) do
    Timex.format!(date, "%-I:%M%p", :strftime)
  end

  def display_date(date) do
    display_date(date, :short)
  end

  def aircraft_display_name(aircraft) do
    "#{aircraft.make} #{aircraft.model}"
  end

  def display_name(user) do
    "#{user.first_name} #{user.last_name}"
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

  def flyer_certificate_inputs() do
    Flight.Accounts.flyer_certificates()
    |> Enum.map(&{String.upcase(&1.slug), &1.slug})
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

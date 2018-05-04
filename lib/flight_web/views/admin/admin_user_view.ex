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

  def medical_approval_buttons() do
    [
      {"None", "0"},
      {"1st Class", "1"},
      {"2nd Class", "2"},
      {"3rd Class", "3"}
    ]
  end

  def role_inputs() do
    [
      {"Student", "student"},
      {"Instructor", "instructor"},
      {"Renter", "renter"},
      {"Admin", "admin"}
    ]
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
end

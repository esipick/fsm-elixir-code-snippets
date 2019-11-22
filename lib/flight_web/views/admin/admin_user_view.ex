defmodule FlightWeb.Admin.UserView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers
  import Scrivener.HTML

  import FlightWeb.Shared.ProfileView

  alias Flight.Accounts
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  def has_billing?(user) do
    Accounts.has_any_role?(user, ["renter", "instructor", "student"])
  end

  def has_appointments?(user) do
    Accounts.has_any_role?(user, ["renter", "instructor", "student"])
  end

  def medical_approval_inputs() do
    0..3
    |> Enum.map(fn medical_rating ->
      {human_readable_medical_rating(medical_rating), medical_rating}
    end)
  end

  def role_inputs(current_user) do
    role_slugs_available_to_user(current_user)
    |> Enum.map(fn role_slug ->
      {String.capitalize(role_slug), role_slug}
    end)
  end

  def role_slugs_available_to_user(user) do
    slugs = Flight.Accounts.Role.available_role_slugs()

    if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
      slugs
    else
      Enum.filter(slugs, fn s -> s != "admin" end)
    end
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
end

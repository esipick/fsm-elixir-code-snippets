defmodule FlightWeb.Admin.UserView do
  use FlightWeb, :view

  import Flight.Auth.Authorization
  import FlightWeb.Shared.ProfileView
  import FlightWeb.ViewHelpers
  import Scrivener.HTML
  alias Flight.Accounts
  alias Flight.Auth.Permission

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

  def user_has_aircraft?(user, aircraft_id) do
    Accounts.has_aircraft?(user, aircraft_id)
  end

  def user_has_instructor?(user, instructor_id) do
    Accounts.has_instructor?(user, instructor_id)
  end

  def user_has_flyer_certificate?(user, cert_slug) do
    Accounts.has_flyer_certificate?(user, cert_slug)
  end

  def flyer_certificate_inputs() do
    Flight.Accounts.flyer_certificates()
    |> Enum.map(&{String.upcase(&1.slug), &1.slug})
  end

  def aircrafts_for_select(aircrafts),
    do: aircrafts |> Enum.map(&{"#{&1.make} #{&1.model} (#{&1.tail_number})", &1.id})

  def main_instructor_select(instructors),
    do: [{"None", nil} | instructors_for_select(instructors)]

  def instructors_for_select(instructors),
    do: instructors |> Enum.map(&{"#{&1.first_name} #{&1.last_name}", &1.id})

  def add_user_label_for_role(role) do
    case role.slug do
      "admin" -> "Add an #{singular_label_for_role(role)}"
      _ -> "Add a #{singular_label_for_role(role)}"
    end
  end
end

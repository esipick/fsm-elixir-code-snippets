defmodule FlightWeb.API.UserView do
  use FlightWeb, :view

  alias FlightWeb.API.UserView

  def render("show.json", %{user: user}) do
    %{data: render("user.json", user: user)}
  end

  def render("index.json", %{users: users, form: form}) do
    %{data: render_many(users, UserView, form, as: :user)}
  end

  def render("autocomplete.json", %{users: users}) do
    %{data: render_many(users, UserView, "skinny_user.json", as: :user)}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      avatar: avatar_urls(user),
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      balance: user.balance,
      phone_number: user.phone_number,
      address_1: user.address_1,
      city: user.city,
      state: user.state,
      zipcode: user.zipcode,
      flight_training_number: user.flight_training_number,
      medical_rating: user.medical_rating,
      medical_expires_at: user.medical_expires_at,
      certificate_number: user.certificate_number,
      awards: user.awards,
      roles: Enum.map(user.roles, & &1.slug),
      permissions: Flight.Auth.Authorization.permission_slugs_for_user(user),
      aircrafts: user.aircrafts,
      flyer_certificates: Enum.map(user.flyer_certificates, & &1.slug),
      instructors: user.instructors,
      main_instructor: user.main_instructor,
      main_instructor_id: user.main_instructor_id,
      stripe_customer_id: user.stripe_customer_id,
      stripe_account_id: nil,
      school_id: user.school_id,
      show_student_accounts_summary: user.school.show_student_accounts_summary,
      show_student_flight_hours: user.school.show_student_flight_hours,

      date_of_birth: user.date_of_birth,
      gender: user.gender,
      emergency_contact_no: user.emergency_contact_no,
      d_license_no: user.d_license_no,
      d_license_expires_at: user.d_license_expires_at,
      d_license_country: user.d_license_country,
      d_license_state: user.d_license_state,
      passport_no: user.passport_no,
      passport_expires_at: user.passport_expires_at,
      passport_country: user.passport_country,
      passport_issuer_name: user.passport_issuer_name,
      last_faa_flight_review_at: user.last_faa_flight_review_at,
      renter_policy_no: user.renter_policy_no,
      renter_insurance_expires_at: user.renter_insurance_expires_at,

      pilot_current_certificate: user.pilot_current_certificate,
      pilot_aircraft_categories: user.pilot_aircraft_categories,
      pilot_class: user.pilot_class,
      pilot_ratings: user.pilot_ratings,
      pilot_endorsements: user.pilot_endorsements,
      pilot_certificate_number: user.pilot_certificate_number,
      pilot_certificate_expires_at: user.pilot_certificate_expires_at

    }
  end

  def render("skinny_user.json", %{user: user}) do
    %{
      id: user.id,
      avatar: avatar_urls(user),
      first_name: user.first_name,
      last_name: user.last_name,
      balance: user.balance,
      billing_rate: user.billing_rate,
      email: user.email,
      has_cc: !!user.stripe_customer_id
    }
  end

  def render("directory_user.json", %{user: user}) do
    %{
      id: user.id,
      avatar: avatar_urls(user),
      balance: user.balance,
      first_name: user.first_name,
      last_name: user.last_name,
      phone_number: user.phone_number,
      email: user.email,
      flight_training_number: user.flight_training_number,
      awards: user.awards,
      roles: Enum.map(user.roles, & &1.slug),
      stripe_customer_id: user.stripe_customer_id

    }
  end

  def render("form_items.json", %{form_items: items}) do
    %{data: items}
  end

  def show_preload(user, opts \\ []) do
    user
    |> Flight.Repo.preload(
      [
        :roles,
        :aircrafts,
        :flyer_certificates,
        :instructors,
        :main_instructor,
        [school: :stripe_account]
      ],
      opts
    )
  end

  defp avatar_urls(user) do
    urls = Flight.AvatarUploader.urls({user.avatar, user})
    %{original: urls[:original], thumb: urls[:thumb]}
  end
end

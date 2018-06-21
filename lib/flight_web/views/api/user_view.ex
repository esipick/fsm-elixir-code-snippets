defmodule FlightWeb.API.UserView do
  use FlightWeb, :view

  alias FlightWeb.API.UserView

  def render("show.json", %{user: user}) do
    %{data: render("user.json", user: user)}
  end

  def render("index.json", %{users: users, form: form}) do
    %{data: render_many(users, UserView, form, as: :user)}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
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
      flyer_certificates: Enum.map(user.flyer_certificates, & &1.slug)
    }
  end

  def render("skinny_user.json", %{user: user}) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name
    }
  end

  def render("directory_user.json", %{user: user}) do
    %{
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      phone_number: user.phone_number,
      email: user.email,
      awards: user.awards,
      roles: Enum.map(user.roles, & &1.slug)
    }
  end

  def render("form_items.json", %{form_items: items}) do
    %{data: items}
  end
end
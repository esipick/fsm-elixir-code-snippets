defmodule FlightWeb.API.SchoolView do
  use FlightWeb, :view

  def render("index.json", %{school: school}) do
    %{
      id: school.id,
      name: school.name,
      city: school.city,
      state: school.state,
      zipcode: school.zipcode,
      phone_number: school.phone_number,
      email: school.email,
      website: school.website,
      contact_first_name: school.contact_first_name,
      contact_last_name: school.contact_last_name,
      contact_email: school.contact_email,
      contact_phone_number: school.contact_phone_number,
      timezone: school.timezone,
      sales_tax: school.sales_tax,
      archived: school.archived,
      show_student_accounts_summary: school.show_student_accounts_summary,
      show_student_flight_hours: school.show_student_flight_hours,
      student_schedule: school.student_schedule,
      renter_schedule: school.renter_schedule
    }
  end
end

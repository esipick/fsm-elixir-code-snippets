defmodule FlightWeb.Admin.SchoolListItem do
  defstruct [
    :school,
    :name,
    :location,
    :student_count,
    :instructor_count,
    :aircraft_count,
    :payment_status
  ]

  def items_from_schools(schools) do
    schools =
      schools
      |> Flight.Repo.preload(:stripe_account)

    for school <- schools do
      %FlightWeb.Admin.SchoolListItem{
        school: school,
        name: school.name,
        location: location(school),
        student_count: Flight.Accounts.get_user_count(Flight.Accounts.Role.student(), school),
        instructor_count:
          Flight.Accounts.get_user_count(Flight.Accounts.Role.instructor(), school),
        aircraft_count: Flight.Scheduling.visible_aircraft_count(school),
        payment_status: payment_status(school.stripe_account)
      }
    end
  end

  def location(school) do
    "#{school.city}, #{school.state}"
  end

  def payment_status(stripe_account) do
    cond do
      !stripe_account ->
        :disconnected

      stripe_account.charges_enabled && stripe_account.payouts_enabled &&
          stripe_account.details_submitted ->
        :running

      true ->
        :error
    end
  end
end

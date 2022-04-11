defmodule FlightWeb.Student.HomeController do
  use FlightWeb, :controller

  alias Flight.{Accounts, Repo, Scheduling}
  alias Fsm.Aircrafts

  def index(%{assigns: %{current_user: current_user}} = conn, _) do
    instructor_count = Accounts.get_user_count(Accounts.Role.instructor(), conn)
    aircrafts = Scheduling.visible_air_assets(conn)
    aircraft_count = Enum.count(aircrafts)
    aircrafts = aircrafts
                |> Repo.preload([:inspections])
    IO.inspect("Aircrafts #{inspect aircrafts}")
    user = Repo.preload(current_user, [:roles, :aircrafts, :instructors, :main_instructor])
    options =
      cond do
        Accounts.has_role?(user, "instructor") ->
          %{"instructor_user_id" => user.id}

        true ->
          %{"user_id" => user.id}
      end
    appointments =
      Scheduling.get_appointments(options, conn)
      |> Repo.preload([:aircraft, :instructor_user, :simulator, :simulator, :room])

    flight_hrs_billed = Scheduling.calculate_appointments_billing_duration(appointments)

    render(
      conn,
      "index.html",
      user: user,
      instructor_count: instructor_count,
      aircraft_count: aircraft_count,
      hours: flight_hrs_billed,
      show_student_flight_hours: current_user.school.show_student_flight_hours,
      show_student_accounts_summary: current_user.school.show_student_accounts_summary,
      appointments: appointments,
      aircrafts: aircrafts
    )
  end
end

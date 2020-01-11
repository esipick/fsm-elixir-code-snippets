defmodule FlightWeb.API.V2.AppointmentController do
  use FlightWeb, :controller

  alias Flight.Scheduling.Availability
  alias Flight.Scheduling
  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

  def availability(conn, %{"start_at" => start_at_str, "end_at" => end_at_str} = params) do
    {:ok, start_at} = NaiveDateTime.from_iso8601(start_at_str)
    {:ok, end_at} = NaiveDateTime.from_iso8601(end_at_str)

    user_id =
      if user_can?(conn.assigns.current_user, [Permission.new(:appointment, :modify, :all)]) do
        nil
      else
        conn.assigns.current_user.id
      end

    excluded_appointment_ids = [params["excluded_appointment_id"]] |> List.flatten()

    students_available =
      Availability.student_availability(start_at, end_at, excluded_appointment_ids, [], conn, %{
        "user_id" => user_id
      })

    instructors_available =
      Availability.instructor_availability(start_at, end_at, excluded_appointment_ids, [], conn)

    aircrafts_available =
      Availability.aircraft_availability(start_at, end_at, excluded_appointment_ids, [], conn)

    render(
      conn,
      "availability.json",
      students_available: students_available,
      instructors_available: instructors_available,
      aircrafts_available: aircrafts_available
    )
  end

  def index(conn, params) do
    user_id =
      if user_can?(conn.assigns.current_user, [Permission.new(:appointment, :modify, :all)]) do
        Map.get(params, "user_id", nil)
      else
        conn.assigns.current_user.id
      end

    options = Map.merge(params, %{"user_id" => user_id})

    appointments =
      Scheduling.get_appointments(options, conn) |> FlightWeb.API.AppointmentView.preload()

    render(conn, "index.json", appointments: appointments)
  end
end

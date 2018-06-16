defmodule FlightWeb.API.AppointmentController do
  use FlightWeb, :controller

  plug(:get_appointment when action in [:update])

  alias Flight.Scheduling.Availability
  alias Flight.Scheduling
  import Flight.Auth.Authorization
  import Flight.Auth.Permission

  def availability(conn, %{"start_at" => start_at_str, "end_at" => end_at_str} = params) do
    {:ok, start_at} = NaiveDateTime.from_iso8601(start_at_str)
    {:ok, end_at} = NaiveDateTime.from_iso8601(end_at_str)

    excluded_appointment_ids = [params["excluded_appointment_id"]] |> List.flatten()

    students_available =
      Availability.student_availability(start_at, end_at, excluded_appointment_ids)

    instructors_available =
      Availability.instructor_availability(start_at, end_at, excluded_appointment_ids)

    aircrafts_available =
      Availability.aircraft_availability(start_at, end_at, excluded_appointment_ids)

    render(
      conn,
      "availability.json",
      students_available: students_available,
      instructors_available: instructors_available,
      aircrafts_available: aircrafts_available
    )
  end

  def index(conn, params) do
    appointments =
      Scheduling.get_appointments(params)
      |> Flight.Repo.preload([:user, :instructor_user, :aircraft])

    render(conn, "index.json", appointments: appointments)
  end

  def create(conn, %{"data" => appointment_data}) do
    cond do
      conn.assigns.current_user.id not in [
        appointment_data["user_id"],
        appointment_data["instructor_user_id"]
      ] ->
        render_bad_request(conn, "Requesting user must be either user_id or instructor_user_id")

      appointment_data["user_id"] == conn.assigns.current_user.id &&
          !has_permission_slug?(
            conn.assigns.current_user,
            permission_slug(:appointment_user, :modify, :personal)
          ) ->
        render_bad_request(conn)

      appointment_data["instructor_user_id"] == conn.assigns.current_user.id &&
          !has_permission_slug?(
            conn.assigns.current_user,
            permission_slug(:appointment_instructor, :modify, :personal)
          ) ->
        render_bad_request(conn)

      true ->
        case Flight.Scheduling.create_appointment(appointment_data) do
          {:ok, appointment} ->
            appointment = Flight.Repo.preload(appointment, [:user, :instructor_user, :aircraft])
            render(conn, "show.json", appointment: appointment)

          {:error, changeset} ->
            conn
            |> put_status(400)
            |> json(%{errors: json_errors(changeset.errors)})
        end
    end
  end

  def update(conn, %{"data" => appointment_data}) do
    user_id = appointment_data["user_id"] || conn.assigns.appointment.user_id

    instructor_user_id =
      appointment_data["instructor_user_id"] || conn.assigns.appointment.instructor_user_id

    cond do
      conn.assigns.current_user.id not in [
        user_id,
        instructor_user_id
      ] ->
        render_bad_request(conn, "Requesting user must be either user_id or instructor_user_id")

      user_id == conn.assigns.current_user.id &&
          !has_permission_slug?(
            conn.assigns.current_user,
            permission_slug(:appointment_user, :modify, :personal)
          ) ->
        render_bad_request(conn)

      instructor_user_id == conn.assigns.current_user.id &&
          !has_permission_slug?(
            conn.assigns.current_user,
            permission_slug(:appointment_instructor, :modify, :personal)
          ) ->
        render_bad_request(conn)

      true ->
        case Flight.Scheduling.create_appointment(appointment_data, conn.assigns.appointment) do
          {:ok, appointment} ->
            appointment = Flight.Repo.preload(appointment, [:user, :instructor_user, :aircraft])
            render(conn, "show.json", appointment: appointment)

          {:error, changeset} ->
            conn
            |> put_status(400)
            |> json(%{errors: json_errors(changeset.errors)})
        end
    end
  end

  def render_bad_request(conn, message \\ "Unauthorized creation") do
    conn
    |> put_status(400)
    |> json(%{error: message})
  end

  defp get_appointment(conn, _) do
    assign(conn, :appointment, Scheduling.get_appointment(conn.params["id"]))
  end
end

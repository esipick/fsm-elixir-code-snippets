defmodule FlightWeb.API.AppointmentController do
  use FlightWeb, :controller

  plug(:get_appointment when action in [:update, :show, :delete])
  plug(:authorize_modify when action in [:create, :update, :delete])

  alias Flight.Scheduling.Availability
  alias Flight.Scheduling
  import Flight.Auth.Authorization
  alias Flight.Auth.Permission

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
      |> FlightWeb.API.AppointmentView.preload()

    render(conn, "index.json", appointments: appointments)
  end

  def show(conn, _) do
    appointment = FlightWeb.API.AppointmentView.preload(conn.assigns.appointment)

    render(conn, "show.json", appointment: appointment)
  end

  def create(conn, %{"data" => appointment_data}) do
    case Flight.Scheduling.create_appointment(appointment_data) do
      {:ok, appointment} ->
        appointment = FlightWeb.API.AppointmentView.preload(appointment)
        render(conn, "show.json", appointment: appointment)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def update(conn, %{"data" => appointment_data}) do
    case Flight.Scheduling.create_appointment(appointment_data, conn.assigns.appointment) do
      {:ok, appointment} ->
        appointment = FlightWeb.API.AppointmentView.preload(appointment)
        render(conn, "show.json", appointment: appointment)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def delete(conn, _) do
    Scheduling.delete_appointment(conn.assigns.appointment.id)

    conn
    |> resp(204, "")
  end

  def authorize_modify(conn, _) do
    user_id =
      conn.params["data"] |> Optional.map(& &1["user_id"]) || conn.assigns.appointment.user_id

    instructor_user_id_from_appointment =
      case conn.assigns do
        %{appointment: %{instructor_user_id: id}} -> id
        _ -> nil
      end

    instructor_user_id =
      conn.params["data"] |> Optional.map(& &1["instructor_user_id"]) ||
        instructor_user_id_from_appointment

    if user_can?(conn.assigns.current_user, [
         Permission.new(:appointment_user, :modify, {:personal, user_id}),
         Permission.new(:appointment_instructor, :modify, {:personal, instructor_user_id}),
         Permission.new(:appointment, :modify, :all)
       ]) do
      conn
    else
      render_bad_request(
        conn,
        "You must be either the renter or the instructor of the appointment you're trying to create or modify."
      )
    end
  end

  def render_bad_request(
        conn,
        message \\ "You are not authorized to create or change this appointment. Please talk to your school Admin."
      ) do
    conn
    |> put_status(400)
    |> json(%{human_errors: [message]})
    |> halt()
  end

  defp get_appointment(conn, _) do
    assign(conn, :appointment, Scheduling.get_appointment(conn.params["id"]))
  end
end

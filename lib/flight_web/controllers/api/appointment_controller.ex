defmodule FlightWeb.API.AppointmentController do
  use FlightWeb, :controller

  plug(:get_appointment when action in [:update, :show, :delete])
  plug(:authorize_modify when action in [:create, :update, :delete])

  import Flight.Auth.Authorization
  alias Flight.{Scheduling, Repo}
  alias Scheduling.Availability
  alias Flight.Auth.Permission

  def availability(conn, %{"start_at" => start_at_str, "end_at" => end_at_str} = params) do
    {:ok, start_at} = NaiveDateTime.from_iso8601(start_at_str)
    {:ok, end_at} = NaiveDateTime.from_iso8601(end_at_str)

    excluded_appointment_ids = [params["excluded_appointment_id"]] |> List.flatten()

    students_available =
      Availability.student_availability(start_at, end_at, excluded_appointment_ids, [], conn)

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
    status =
      case Integer.parse(params["status"] || "") do
        {value, _} -> value
        :error -> nil
      end

    options = Map.merge(params, %{"status" => status})

    appointments =
      Scheduling.get_appointments(options, conn)
      |> FlightWeb.API.AppointmentView.preload()

    render(conn, "index.json", appointments: appointments)
  end

  def show(conn, _) do
    appointment = FlightWeb.API.AppointmentView.preload(conn.assigns.appointment)
    render(conn, "show.json", appointment: appointment)
  end

  def create(conn, %{"data" => appointment_data}) do
    case Flight.Scheduling.insert_or_update_appointment(
           %Scheduling.Appointment{},
           appointment_data,
           Repo.preload(conn.assigns.current_user, :school),
           conn
         ) do
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
    case Flight.Scheduling.insert_or_update_appointment(
           conn.assigns.appointment,
           appointment_data,
           Repo.preload(conn.assigns.current_user, :school),
           conn
         ) do
      {:ok, appointment} ->
        appointment = FlightWeb.API.AppointmentView.preload(appointment)
        render(conn, "show.json", appointment: appointment)

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
    end
  end

  def delete(%{assigns: %{appointment: appointment, current_user: user}} = conn, _) do
    case Scheduling.Appointment.allowed_for_archive?(appointment) do
      true ->
        Scheduling.delete_appointment(appointment.id, user, conn)

        conn
        |> resp(204, "")

      false ->
        conn
        |> put_status(401)
        |> json(%{human_errors: ["Appointment is ended or paid."]})
    end
  end

  defp authorize_modify(conn, _) do
    current_user = conn.assigns.current_user
    user_id_param = conn.params["data"] |> Optional.map(& &1["user_id"])

    user_id =
      with %Scheduling.Appointment{} = appointment <- conn.assigns[:appointment],
           true <- user_id_param == nil or appointment.user_id != current_user.id do
        appointment.user_id
      else
        _ -> user_id_param
      end

    instructor_user_id_from_appointment =
      case conn.assigns do
        %{appointment: %{instructor_user_id: id}} -> id
        _ -> nil
      end

    instructor_user_id =
      conn.params["data"] |> Optional.map(& &1["instructor_user_id"]) ||
        instructor_user_id_from_appointment

    cond do
      user_can?(current_user, [
        Permission.new(:appointment_user, :modify, {:personal, user_id}),
        Permission.new(:appointment_instructor, :modify, {:personal, instructor_user_id}),
        Permission.new(:appointment, :modify, :all)
      ]) ->
        conn

      true ->
        render_bad_request(conn)
    end
  end

  defp render_bad_request(
         conn,
         message \\ "You are not authorized to create or change this appointment. Please talk to your school's Admin."
       ) do
    conn
    |> put_status(401)
    |> json(%{human_errors: [message]})
    |> halt()
  end

  defp get_appointment(conn, _) do
    appointment = Scheduling.get_appointment(conn.params["id"], conn)

    cond do
      appointment && appointment.archived ->
        conn
        |> put_status(401)
        |> json(%{human_errors: ["Appointment already removed please recreate it"]})
        |> halt()

      true ->
        assign(conn, :appointment, appointment)
    end
  end
end

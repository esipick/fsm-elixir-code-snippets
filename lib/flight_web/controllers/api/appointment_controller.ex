defmodule FlightWeb.API.AppointmentController do
  use FlightWeb, :controller

  plug(:get_appointment when action in [:update, :show, :delete])
  plug(:authorize_modify when action in [:create, :update, :delete])

  import Flight.Auth.Authorization
  alias Flight.{Scheduling, Repo}
  alias Flight.Billing.CreateInvoiceFromAppointment
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


    mechanics_available =
      Availability.mechanic_availability(start_at, end_at, excluded_appointment_ids, [], conn)


    aircrafts_available =
      Availability.aircraft_availability(start_at, end_at, excluded_appointment_ids, [], conn)

    simulators_available = Enum.filter(aircrafts_available, &(&1.aircraft.simulator))
    aircrafts_available = aircrafts_available -- simulators_available

    rooms_available =
      Availability.room_availability(start_at, end_at, excluded_appointment_ids, [], conn)

    render(
      conn,
      "availability.json",
      students_available: students_available,
      instructors_available: instructors_available,
      mechanics_available: mechanics_available,
      aircrafts_available: aircrafts_available,
      simulators_available: simulators_available,
      rooms_available: rooms_available
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

  def create(conn, %{"data" => %{"recurring" => "true"} = appointment_data}) do
    {:ok, data} = Flight.Scheduling.insert_recurring_appointments(
      appointment_data,
      Repo.preload(conn.assigns.current_user, :school),
      conn)

    errors = Map.get(data, :errors) || %{}
    human_errors = Enum.reduce(errors, %{}, fn {time, anError}, acc ->
      errors = FlightWeb.ViewHelpers.human_error_messages(anError)
      Map.put(acc, time, errors)
    end)

    conn
    |> json(%{human_errors: human_errors})
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

  def update(%{assigns: %{appointment: appointment, current_user: user}} = conn, %{"data" => appointment_data}) do
    if !user_can?(user, [Permission.new(:appointment, :modify, :all)]) && Scheduling.Appointment.is_paid?(appointment) do
      conn
      |> put_status(401)
      |> json(%{human_errors: ["Can't modify paid appointment. Please contact administrator to re-schedule or update the content."]})
    else
      case Flight.Scheduling.insert_or_update_appointment(
             conn.assigns.appointment,
             appointment_data,
             Repo.preload(conn.assigns.current_user, :school),
             conn
           ) do
        {:ok, appointment} ->
          appointment = FlightWeb.API.AppointmentView.preload(appointment)
          update_invoice(appointment, conn)

          render(conn, "show.json", appointment: appointment)

        {:error, changeset} ->
          conn
          |> put_status(400)
          |> json(%{human_errors: FlightWeb.ViewHelpers.human_error_messages(changeset)})
      end
    end
  end

  def delete(%{assigns: %{appointment: appointment, current_user: user}} = conn, _) do
    if user_can?(user, [Permission.new(:appointment, :modify, :all)]) do
      delete_appointment(appointment, user, conn)
    else
      if Scheduling.Appointment.is_paid?(appointment) do
        conn
        |> put_status(401)
        |> json(%{human_errors: ["Can't delete paid appointment. Please contact administrator to re-schedule or delete the content."]})
      else
        instructor_user_id = Map.get(appointment, :instructor_user_id)
        owner_user_id = Map.get(appointment, :owner_user_id)

        mechanic_user_id = Map.get(appointment, :mechanic_user_id)

        owner_permission =
          if owner_user_id == user.id do
            [
              Permission.new(
                :appointment_instructor,
                :modify,
                {:personal, owner_user_id})
            ]
          else
            []
          end

        owner_permission =
          if mechanic_user_id == user.id do
            [
              Permission.new(
                :appointment_mechanic,
                :modify,
                {:personal, mechanic_user_id})
            ]
          else
            []
          end

        instructor_user_id =
          if instructor_user_id == "" do
            nil
          else
            instructor_user_id
          end

        mechanic_user_id =
          if mechanic_user_id == "" do
            nil
          else
            mechanic_user_id
          end

        if user_can?(user, [
                             Permission.new(:appointment_user, :modify, {:personal, appointment.user_id}),
                             Permission.new(
                               :appointment_instructor,
                               :modify,
                               {:personal, instructor_user_id}
                             ),
                             Permission.new(
                               :appointment_mechanic,
                               :modify,
                               {:personal, mechanic_user_id}
                             )
                           ] ++ owner_permission) do
          delete_appointment(appointment, user, conn)
        else
          conn
          |> put_status(401)
          |> json(%{human_errors: ["Can't delete appointment associated with other user."]})
        end
      end
    end
  end

  defp authorize_modify(conn, _) do
    current_user = conn.assigns.current_user
    user_id_param = conn.params["data"] |> Optional.map(& &1["user_id"])
    twenty_four_hours = 24 * 60 * 60

    {user_id, end_at} =
      with %Scheduling.Appointment{} = appointment <- conn.assigns[:appointment] do
          #  true <- user_id_param == nil or appointment.owner_user_id != current_user.id do
           end_at =
              if appointment.end_at, do: NaiveDateTime.add(appointment.end_at, twenty_four_hours), else: nil

        {appointment.user_id, end_at}
      else
        _ -> {user_id_param, nil}
      end

    instructor_id_param = conn.params["data"] |> Optional.map(& &1["instructor_user_id"])

    owner_instructor_user_id =
      with %Scheduling.Appointment{} = appointment <- conn.assigns[:appointment],
           true <- instructor_id_param == nil or instructor_id_param == "" or appointment.owner_user_id != current_user.id do
        appointment.owner_user_id
      else
        _ -> current_user.id
      end

    mechanic_id_param = conn.params["data"] |> Optional.map(& &1["mechanic_user_id"])

    owner_mechanic_user_id =
      with %Scheduling.Appointment{} = appointment <- conn.assigns[:appointment],
            true <- mechanic_id_param == nil or mechanic_id_param == "" or appointment.owner_user_id != current_user.id do
        appointment.owner_user_id
      else
        _ -> current_user.id
    end

    apnmt = conn.assigns[:appointment]
    now = NaiveDateTime.utc_now()
    apnmt_end_at = # because end_at can be nil because of the with condition on line 164
      if apnmt != nil && apnmt.end_at != nil, do: NaiveDateTime.add(apnmt.end_at, twenty_four_hours), else: nil

    restrict_modify =
      if apnmt_end_at && NaiveDateTime.compare(apnmt_end_at, now) == :lt, do: true, else: false

    owner_instructor_permissions =
      if conn.assigns[:appointment] && (end_at == nil or NaiveDateTime.compare(end_at, now) == :gt) && !restrict_modify do
        Permission.new(:appointment_instructor, :modify, {:personal, owner_instructor_user_id})

      else
        Permission.new(:appointment_instructor, :view, {:personal, owner_instructor_user_id})
      end

    instructor_user_id_from_appointment =
      case conn.assigns do
        %{appointment: %{instructor_user_id: nil}} -> owner_instructor_user_id
        %{appointment: %{instructor_user_id: id}} -> id
        _ -> owner_instructor_user_id
      end

    instructor_user_id =
      if (conn.params["data"] |> Optional.map(& &1["instructor_user_id"])) not in [nil, ""] and
         (conn.assigns[:appointment] != nil and conn.assigns[:appointment].instructor_user_id == current_user.id and conn.assigns[:appointment].status != :paid) do
        (conn.params["data"] |> Optional.map(& &1["instructor_user_id"]))
      else
        instructor_user_id_from_appointment
      end

    instructor_permissions =
      if restrict_modify do
        Permission.new(:appointment_instructor, :view, {:personal, instructor_user_id})

      else
        Permission.new(:appointment_instructor, :modify, {:personal, instructor_user_id})
      end

    owner_mechanic_permissions =
      if conn.assigns[:appointment] && (end_at == nil or NaiveDateTime.compare(end_at, now) == :gt) && !restrict_modify do
        Permission.new(:appointment_mechanic, :modify, {:personal, owner_mechanic_user_id})

      else
        Permission.new(:appointment_mechanic, :view, {:personal, owner_mechanic_user_id})
      end

    mechanic_user_id_from_appointment =
      case conn.assigns do
        %{appointment: %{mechanic_user_id: nil}} -> owner_mechanic_user_id
        %{appointment: %{mechanic_user_id: id}} -> id
        _ -> owner_mechanic_user_id
      end

    mechanic_user_id =
      if (conn.params["data"] |> Optional.map(& &1["mechanic_user_id"])) not in [nil, ""] and
         (conn.assigns[:appointment] != nil and conn.assigns[:appointment].mechanic_user_id == current_user.id and conn.assigns[:appointment].status != :paid) do
        (conn.params["data"] |> Optional.map(& &1["mechanic_user_id"]))
      else
        mechanic_user_id_from_appointment
      end

    mechanic_permissions =
      if restrict_modify do
        Permission.new(:appointment_mechanic, :view, {:personal, mechanic_user_id})

      else
        Permission.new(:appointment_mechanic, :modify, {:personal, mechanic_user_id})
      end

    cond do
      user_can?(current_user,
        [instructor_permissions,
          owner_instructor_permissions,
          mechanic_permissions,
          owner_mechanic_permissions,
          Permission.new(:appointment, :modify, :all)]) ->
        conn

      user_can?(current_user,
        [Permission.new(:appointment_user, :modify, {:personal, user_id})]) -> #student
        if (end_at == nil or NaiveDateTime.compare(NaiveDateTime.utc_now(), end_at) == :lt) do
            conn
          else
            render_bad_time_request(conn)
          end

      true ->
        render_bad_request(conn)
    end
  end

  defp render_bad_time_request(
         conn,
         message \\ "You are not authorized to change an appointment after 24 hours of its end time. Please talk to your assigned Instructor, Dispatcher or school's Admin."
       ) do
    conn
    |> put_status(401)
    |> json(%{human_errors: [message]})
    |> halt()
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

  defp update_invoice(appointment, conn) do
    case CreateInvoiceFromAppointment.fetch_invoice(appointment.id) do
      {:ok, invoice} ->
        params = %{"payment_option" => invoice.payment_option}
        CreateInvoiceFromAppointment.sync_invoice(appointment, invoice, params, conn)

      _ ->
        nil
    end
  end

  defp delete_appointment(appointment, user, conn) do
    Scheduling.delete_appointment(appointment.id, user, conn)

    conn
    |> resp(204, "")
  end
end

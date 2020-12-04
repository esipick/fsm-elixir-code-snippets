defmodule Fsm.Scheduling do
  alias Flight.Scheduling.{
    Aircraft,
    Availability,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability
  }

  alias Fsm.Accounts
  alias Flight.Auth.Permission

  alias Fsm.Scheduling.Appointment
  alias Fsm.Scheduling.SchedulingQueries

  alias Flight.Repo
  alias Fsm.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Pipe
  import Fsm.Walltime, only: [walltime_to_utc: 2, utc_to_walltime: 2]
  alias Flight.Inspections


  def send_changed_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if appointment.user_id && modifying_user.id != appointment.user_id do
      Flight.PushNotifications.appointment_changed_notification(
        appointment.user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end

    if appointment.instructor_user && appointment.instructor_user.id != modifying_user.id do
      Flight.PushNotifications.appointment_changed_notification(
        appointment.instructor_user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end
  end


  def send_created_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if appointment.user_id && modifying_user.id != appointment.user_id do
      Flight.PushNotifications.appointment_created_notification(
        appointment.user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end

    if appointment.instructor_user && appointment.instructor_user.id != modifying_user.id do
      Flight.PushNotifications.appointment_created_notification(
        appointment.instructor_user,
        modifying_user,
        appointment
      )
      |> Mondo.PushService.publish()
    end
  end

  def upsert_appointment(
        appointment,
        attrs,
        modifying_user,
        school_context
      ) do
    school = SchoolScope.get_school(school_context.school_id)
    role = List.first(Repo.preload(modifying_user, :roles).roles)

    attrs =
      if Map.get(attrs, :instructor_user_id) in [nil, ""] and Map.get(role, :slug) == "instructor" do
        Map.put(attrs, "owner_user_id", modifying_user.id)
      else
        attrs
      end
    changeset =
      appointment
      |> SchoolScope.school_changeset(school_context)
      |> Appointment.changeset(attrs, school.timezone)

    is_create? = is_nil(appointment.id)

    if changeset.valid? do
      {temp_changeset, appointment} =
        with true <- is_create?,
             {:ok, item} <- Repo.insert(changeset) do
          {item, Map.put(appointment, :id, item.id)}
        else
          _ -> {changeset, appointment}
        end

      changeset =
        temp_changeset
        |> Appointment.changeset(%{}, school.timezone)

      {:ok, _} = apply_action(changeset, :insert)

      # |> utc_to_walltime(school.timezone)
      start_at = get_field(changeset, :start_at)
      # |> utc_to_walltime(school.timezone)
      end_at = get_field(changeset, :end_at)
      user_id = get_field(changeset, :user_id)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id) || get_field(changeset, :simulator_id)
      room_id = get_field(changeset, :room_id)
      _type = get_field(changeset, :type)

      excluded_appointment_ids =
        if appointment.id do
          [appointment.id]
        else
          []
        end

      # if appointment has started. do not let instructor and 

      status =
        if user_id && user_id != "" do
          Availability.user_with_permission_status(
            Permission.permission_slug(:appointment_user, :modify, :personal),
            user_id,
            start_at,
            end_at,
            excluded_appointment_ids,
            [],
            school_context
          )
        else
          :available
        end

      changeset =
        case status do
          :available ->
            changeset

          _ ->
            add_error(changeset, :renter_student, "already has an appointment at this time.",
              status: :unavailable
            )
        end

      changeset =
        if instructor_user_id do
          status =
            Availability.user_with_permission_status(
              Permission.permission_slug(:appointment_instructor, :modify, :personal),
              instructor_user_id,
              start_at,
              end_at,
              excluded_appointment_ids,
              [],
              school_context
            )

          case status do
            :available -> changeset
            other -> add_error(changeset, :instructor, "is #{other}", status: status)
          end
        else
          changeset
        end

      changeset =
        if aircraft_id do
          status =
            Availability.aircraft_status(
              aircraft_id,
              start_at,
              end_at,
              excluded_appointment_ids,
              [],
              school_context
            )

          case status do
            :available ->
              changeset

            other ->
              key = if get_field(changeset, :simulator_id), do: :simulator, else: :aircraft

              add_error(changeset, key, "is #{other}", status: status)
          end
        else
          changeset
        end

      changeset =
        if room_id do
          status =
            Availability.room_status(
              room_id,
              start_at,
              end_at,
              excluded_appointment_ids,
              [],
              school_context
            )

          case status do
            :available ->
              changeset

            other ->
              add_error(changeset, :room, "is #{other}", status: status)
          end
        else
          changeset
        end

      new_aircraft_id = get_change(changeset, :aircraft_id) || get_field(changeset, :aircraft_id)

      new_simulator_id =
        get_change(changeset, :simulator_id) || get_field(changeset, :simulator_id)

      {should_delete_item, changeset} =
        if (appointment.aircraft_id != nil && appointment.aircraft_id != new_aircraft_id) or
             (appointment.simulator_id != nil && appointment.simulator_id != new_simulator_id) do
          changeset =
            changeset
            |> Appointment.changeset(
              %{
                start_tach_time: nil,
                end_tach_time: nil,
                start_hobbs_time: nil,
                end_hobbs_time: nil
              },
              school.timezone
            )

          {true, changeset}
        else
          {false, changeset}
        end

      case Repo.insert_or_update(changeset) do
        {:ok, appointment} ->
          if should_delete_item do
            Flight.Bills.delete_appointment_aircraft(appointment.id, appointment.aircraft_id)
          end

          Mondo.Task.start(fn ->
            #            if Enum.count(changeset.changes) > 0 do
            if is_create? do
              send_created_notifications(appointment, modifying_user)
            end

            if Enum.count(changeset.changes) > 0 and !is_create? do
              send_changed_notifications(appointment, modifying_user)
            end

            #            end
          end)

          {:ok, appointment}

        other ->
          if Map.get(temp_changeset, :id) != nil && is_create? == true,
            do: Repo.delete(temp_changeset),
            else: nil

          other
      end
    else
      {:error, changeset}
    end
  end

  def insert_or_update_appointment(
        appointment,
        attrs,
        modifying_user,
        context
      ) do
    Repo.transaction(fn ->
      upsert_appointment(appointment, attrs, modifying_user, context)
      |> case do
        {:ok, appointment} -> appointment
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def create_appointment(%{context: %{current_user: %{school_id: school_id, id: user_id}}}=context, appointment_data) do
    %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
    school = Fsm.SchoolScope.get_school(school_id)
    context = %{assigns: %{current_user: current_user}, school_id: school_id}
    case insert_or_update_appointment(
           %Appointment{},
           appointment_data,
           Repo.preload(context.assigns.current_user, :school),
           context
         ) do
      {:ok, appointment} ->
        {:ok, appointment}

      {:error, changeset} ->
        IO.inspect(changeset)
        {:error, :failed}
    end
  end

  ##
  # List Appointments
  ##
  def list_aircraft_appointments(page, per_page, sort_field, sort_order, params, school_context) do
    filter = Map.put(params, :aircraft_id_is_not_null, true)

    SchedulingQueries.list_appointments_query(
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      school_context
    )
    |> Repo.all()

    #    |> FlightWeb.API.AppointmentView.preload()
  end

  ##
  # List Appointments
  ##
  def list_appointments(page, per_page, sort_field, sort_order, filter, school_context) do
    SchedulingQueries.list_appointments_query(
      page,
      per_page,
      sort_field,
      sort_order,
      filter,
      school_context
    )
    |> Repo.all()

    #    |> FlightWeb.API.AppointmentView.preload()
  end

  def visible_air_assets(school_context) do
    SchedulingQueries.visible_air_assets_query(school_context)
    |> Repo.all()
  end

  def apply_utc_timezone(changeset, key, timezone) do
    case get_change(changeset, key) do
      nil -> changeset
      change -> put_change(changeset, key, walltime_to_utc(change, timezone))
    end
  end
end

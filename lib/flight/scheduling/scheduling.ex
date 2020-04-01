defmodule Flight.Scheduling do
  alias Flight.Scheduling.{
    Aircraft,
    Appointment,
    Availability,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability
  }

  alias Flight.Repo
  alias Flight.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Flight.Auth.Permission, only: [permission_slug: 3]
  import Pipe
  import Flight.Walltime, only: [walltime_to_utc: 2, utc_to_walltime: 2]

  def admin_create_aircraft(attrs, school_context) do
    result =
      %Aircraft{}
      |> SchoolScope.school_changeset(school_context)
      |> Aircraft.admin_changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, aircraft} ->
        date_inspections = [
          %DateInspection{name: "Annual", aircraft_id: aircraft.id},
          %DateInspection{name: "Transponder", aircraft_id: aircraft.id},
          %DateInspection{name: "Altimeter", aircraft_id: aircraft.id},
          %DateInspection{name: "ELT", aircraft_id: aircraft.id}
        ]

        tach_inspections = [
          %TachInspection{name: "100hr", aircraft_id: aircraft.id}
        ]

        for date_inspection <- date_inspections do
          %Inspection{}
          |> Inspection.changeset(DateInspection.attrs(date_inspection))
          |> Repo.insert()
        end

        for tach_inspection <- tach_inspections do
          %Inspection{}
          |> Inspection.changeset(TachInspection.attrs(tach_inspection))
          |> Repo.insert()
        end

      _ ->
        {}
    end

    result
  end

  def visible_aircraft_query(school_context, search_term \\ "") do
    Aircraft
    |> Flight.Scheduling.Search.Aircraft.run(search_term)
    |> order_by([a], asc: [a.make, a.model, a.tail_number])
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.archived == false)
  end

  def visible_aircrafts(school_context) do
    visible_aircraft_query(school_context)
    |> Repo.all()
  end

  def visible_aircraft_count(school_context) do
    visible_aircraft_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def get_aircraft(id, school_context) do
    visible_aircraft_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def admin_update_aircraft(aircraft, attrs) do
    aircraft
    |> Aircraft.admin_changeset(attrs)
    |> Repo.update()
  end

  def archive_aircraft(%Aircraft{} = aircraft) do
    aircraft
    |> Aircraft.archive_changeset(%{archived: true})
    |> Repo.update()
  end

  #
  # Inspections
  #

  def get_inspection(id), do: Repo.get(Inspection, id)
  def delete_inspection!(inspection), do: Repo.delete(inspection)

  def create_date_inspection(attrs) do
    result =
      %DateInspection{}
      |> DateInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:insert)

    case result do
      {:ok, date_inspection} ->
        %Inspection{}
        |> Inspection.changeset(DateInspection.attrs(date_inspection))
        |> Repo.insert()

      error ->
        error
    end
  end

  def create_tach_inspection(attrs) do
    result =
      %TachInspection{}
      |> TachInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:insert)

    case result do
      {:ok, date_inspection} ->
        %Inspection{}
        |> Inspection.changeset(TachInspection.attrs(date_inspection))
        |> Repo.insert()

      error ->
        error
    end
  end

  def update_inspection(%Inspection{type: "date"} = inspection, attrs) do
    result =
      inspection
      |> Inspection.to_specific()
      |> DateInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:update)

    case result do
      {:ok, date_inspection} ->
        inspection
        |> Inspection.changeset(DateInspection.attrs(date_inspection))
        |> Repo.update()

      error ->
        error
    end
  end

  def update_inspection(%Inspection{type: "tach"} = inspection, attrs) do
    result =
      inspection
      |> Inspection.to_specific()
      |> TachInspection.changeset(attrs)
      |> Ecto.Changeset.apply_action(:update)

    case result do
      {:ok, tach_inspection} ->
        inspection
        |> Inspection.changeset(TachInspection.attrs(tach_inspection))
        |> Repo.update()

      error ->
        error
    end
  end

  ##
  # Appointment
  ##

  def get_appointments(options, school_context) do
    school = SchoolScope.get_school(school_context)

    is_walltime = options["walltime"] == "true"

    from_value =
      case NaiveDateTime.from_iso8601(options["from"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    to_value =
      case NaiveDateTime.from_iso8601(options["to"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    start_at_after_value =
      case NaiveDateTime.from_iso8601(options["start_at_after"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    user_id_value = options["user_id"]
    instructor_user_id_value = options["instructor_user_id"]
    aircraft_id_value = options["aircraft_id"]

    from(a in Appointment, where: a.archived == false)
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(start_at_after_value, &where(&1, [a], a.start_at >= ^start_at_after_value))
    |> pass_unless(
      from_value && to_value,
      &Availability.overlap_query(&1, from_value, to_value)
    )
    |> pass_unless(user_id_value, &where(&1, [a], a.user_id == ^user_id_value))
    |> pass_unless(aircraft_id_value, &where(&1, [a], a.aircraft_id == ^aircraft_id_value))
    |> pass_unless(
      instructor_user_id_value,
      &from(a in &1, where: a.instructor_user_id == ^instructor_user_id_value)
    )
    |> pass_unless(options["status"], &where(&1, [a], a.status == ^options["status"]))
    # |> limit(200)
    |> order_by([a], desc: a.start_at)
    |> Repo.all()
    |> pass_unless(
      !is_walltime,
      &apply_timezone(&1, SchoolScope.get_school(school_context).timezone)
    )
  end

  def apply_timezone(appointments, timezone) when is_list(appointments) do
    appointments
    |> Enum.map(fn appointment -> apply_timezone(appointment, timezone) end)
  end

  def apply_timezone(appointment_or_unavailability, timezone) do
    %{
      appointment_or_unavailability
      | start_at: walltime_to_utc(appointment_or_unavailability.start_at, timezone),
        end_at: walltime_to_utc(appointment_or_unavailability.end_at, timezone)
    }
  end

  def unapply_timezone(%Appointment{} = appointment, timezone) do
    %Appointment{
      appointment
      | start_at: utc_to_walltime(appointment.start_at, timezone),
        end_at: utc_to_walltime(appointment.end_at, timezone)
    }
  end

  def get_appointment(id, school_context) do
    school = SchoolScope.get_school(school_context)

    Appointment
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
    |> apply_timezone(school.timezone)
  end

  def insert_or_update_appointment(
        appointment,
        attrs,
        modifying_user,
        school_context
      ) do
    school = SchoolScope.get_school(school_context)

    changeset =
      appointment
      |> SchoolScope.school_changeset(school_context)
      |> Appointment.changeset(attrs)
      |> Appointment.apply_timezone_changeset(school.timezone)

    is_create? = is_nil(appointment.id)

    if changeset.valid? do
      {:ok, _} = apply_action(changeset, :insert)

      start_at = get_field(changeset, :start_at)
      end_at = get_field(changeset, :end_at)
      user_id = get_field(changeset, :user_id)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id)
      _type = get_field(changeset, :type)

      excluded_appointment_ids =
        if appointment.id do
          [appointment.id]
        else
          []
        end

      status =
        Availability.user_with_permission_status(
          permission_slug(:appointment_user, :modify, :personal),
          user_id,
          walltime_to_utc(start_at, school.timezone),
          walltime_to_utc(end_at, school.timezone),
          excluded_appointment_ids,
          [],
          school_context
        )

      changeset =
        case status do
          :available ->
            changeset

          _ ->
            add_error(changeset, :renter, "has already an appointment at this time",
              status: :unavailable
            )
        end

      changeset =
        if instructor_user_id do
          status =
            Availability.user_with_permission_status(
              permission_slug(:appointment_instructor, :modify, :personal),
              instructor_user_id,
              walltime_to_utc(start_at, school.timezone),
              walltime_to_utc(end_at, school.timezone),
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
              walltime_to_utc(start_at, school.timezone),
              walltime_to_utc(end_at, school.timezone),
              excluded_appointment_ids,
              [],
              school_context
            )

          case status do
            :available -> changeset
            other -> add_error(changeset, :aircraft, "is #{other}", status: status)
          end
        else
          changeset
        end

      case Repo.insert_or_update(changeset) do
        {:ok, appointment} ->
          Mondo.Task.start(fn ->
            if Enum.count(changeset.changes) > 0 do
              if is_create? do
                send_created_notifications(appointment, modifying_user)
              else
                send_changed_notifications(appointment, modifying_user)
              end
            end
          end)

          {:ok, apply_timezone(appointment, school.timezone)}

        other ->
          other
      end
    else
      {:error, changeset}
    end
  end

  def get_unavailability(id, school_context) do
    school = SchoolScope.get_school(school_context)

    Unavailability
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
    |> apply_timezone(school.timezone)
  end

  def get_unavailabilities(options, school_context) do
    school = SchoolScope.get_school(school_context)

    is_walltime = options["walltime"] == "true"

    from_value =
      case NaiveDateTime.from_iso8601(options["from"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    to_value =
      case NaiveDateTime.from_iso8601(options["to"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    start_at_after_value =
      case NaiveDateTime.from_iso8601(options["start_at_after"] || "") do
        {:ok, date} ->
          if is_walltime do
            date
          else
            utc_to_walltime(date, school.timezone)
          end

        _ ->
          nil
      end

    instructor_user_id_value = options["instructor_user_id"]
    aircraft_id_value = options["aircraft_id"]

    from(a in Unavailability)
    |> SchoolScope.scope_query(school_context)
    |> pass_unless(start_at_after_value, &where(&1, [a], a.start_at >= ^start_at_after_value))
    |> pass_unless(
      from_value && to_value,
      &Availability.overlap_query(&1, from_value, to_value)
    )
    |> pass_unless(aircraft_id_value, &where(&1, [a], a.aircraft_id == ^aircraft_id_value))
    |> pass_unless(
      instructor_user_id_value,
      &from(a in &1, where: a.instructor_user_id == ^instructor_user_id_value)
    )
    # |> limit(200)
    |> order_by([a], desc: a.start_at)
    |> Repo.all()
    |> pass_unless(
      !is_walltime,
      &apply_timezone(&1, SchoolScope.get_school(school_context).timezone)
    )
  end

  def insert_or_update_unavailability(
        unavailability,
        attrs,
        school_context
      ) do
    school = SchoolScope.get_school(school_context)

    changeset =
      unavailability
      |> SchoolScope.school_changeset(school)
      |> Unavailability.changeset(attrs)
      |> Unavailability.apply_timezone_changeset(school.timezone)

    if changeset.valid? do
      {:ok, _} = apply_action(changeset, :insert)

      start_at = get_field(changeset, :start_at)
      end_at = get_field(changeset, :end_at)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id)

      excluded_unavailability_ids =
        if unavailability.id do
          [unavailability.id]
        else
          []
        end

      changeset =
        if instructor_user_id do
          status =
            Availability.user_with_permission_status(
              :unavailability,
              permission_slug(:appointment_instructor, :modify, :personal),
              instructor_user_id,
              walltime_to_utc(start_at, school.timezone),
              walltime_to_utc(end_at, school.timezone),
              [],
              excluded_unavailability_ids,
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
              :unavailability,
              aircraft_id,
              walltime_to_utc(start_at, school.timezone),
              walltime_to_utc(end_at, school.timezone),
              [],
              excluded_unavailability_ids,
              school_context
            )

          case status do
            :available -> changeset
            other -> add_error(changeset, :aircraft, "is #{other}", status: status)
          end
        else
          changeset
        end

      case Repo.insert_or_update(changeset) do
        {:ok, unavailability} ->
          {:ok, apply_timezone(unavailability, school.timezone)}

        other ->
          other
      end
    else
      {:error, changeset}
    end
  end

  def delete_unavailability(id, school_context) do
    unavailability = get_unavailability(id, school_context)

    Repo.delete!(unavailability)
  end

  def send_created_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if modifying_user.id != appointment.user_id do
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

  def send_changed_notifications(appointment, modifying_user) do
    appointment = Repo.preload(appointment, [:user, :instructor_user])

    if modifying_user.id != appointment.user_id do
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

  def delete_appointment(id, deleting_user, school_context) do
    appointment =
      get_appointment(id, school_context)
      |> Repo.preload([:user, :instructor_user])

    Appointment.archive(appointment)

    Mondo.Task.start(fn ->
      if deleting_user.id != appointment.user_id do
        Flight.PushNotifications.appointment_deleted_notification(
          appointment.user,
          deleting_user,
          appointment
        )
        |> Mondo.PushService.publish()
      end

      if appointment.instructor_user && appointment.instructor_user.id != deleting_user.id do
        Flight.PushNotifications.appointment_deleted_notification(
          appointment.instructor_user,
          deleting_user,
          appointment
        )
        |> Mondo.PushService.publish()
      end
    end)
  end
end

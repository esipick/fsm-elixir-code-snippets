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
  alias Flight.Inspections

  def admin_create_aircraft(%{"maintenance_ids" => m_ids } = attrs, %{
      assigns: %{
        current_user: %{school_id: school_id}}} = school_context) when is_list(m_ids) do
    
    Repo.transaction(fn -> 
      with {:ok, %{
          id: id, 
          last_tach_time: tach_hours
          } = aircraft} <- admin_create_aircraft(Map.delete(attrs, "maintenance_ids"), school_context),
        {:ok, :done} <- Inspections.check_and_assign_aircraft_maintenance(id, m_ids, tach_hours, school_id) do
          aircraft
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def admin_create_aircraft(attrs, school_context) do
    IO.inspect(school_context)
    result =
      Map.merge(attrs, %{simulator: false})
      |> MapUtil.atomize_shallow()
      |> insert_aircraft(school_context)

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

        result

      _ ->
        result
    end
  end

  def admin_create_simulator(attrs, school_context) do
    result =
      Map.merge(attrs, %{simulator: true})
      |> MapUtil.atomize_shallow()
      |> insert_aircraft(school_context)

    case result do
      {:ok, aircraft} ->
        date_inspection = %DateInspection{
          name: "Letter of authorization",
          aircraft_id: aircraft.id
        }

        %Inspection{}
        |> Inspection.changeset(DateInspection.attrs(date_inspection))
        |> Repo.insert()

        result

      _ ->
        result
    end
  end

  def insert_aircraft(attrs, school_context) do
    %Aircraft{}
    |> SchoolScope.school_changeset(school_context)
    |> Aircraft.admin_changeset(attrs)
    |> Repo.insert()
  end

  def visible_aircraft_query(school_context, search_term \\ "") do
    aircraft_query(school_context, search_term)
    |> where([a], a.archived == false)
    |> where([a], a.simulator == false)
    |> order_by([a], asc: [a.make, a.model, a.tail_number])
  end

  def visible_simulator_query(school_context, search_term \\ "") do
    aircraft_query(school_context, search_term)
    |> where([a], a.archived == false)
    |> where([a], a.simulator == true)
    |> order_by([a], asc: [a.name])
  end

  def visible_air_assets_query(school_context, search_term \\ "") do
    aircraft_query(school_context, search_term)
    |> where([a], a.archived == false)
    |> order_by([a], asc: [a.make, a.model, a.tail_number, a.name])
  end

  def aircraft_query(school_context, search_term \\ "") do
    Aircraft
    |> Flight.Scheduling.Search.Aircraft.run(search_term)
    |> SchoolScope.scope_query(school_context)
  end

  def visible_air_assets(school_context) do
    visible_air_assets_query(school_context) |> Repo.all()
  end

  def visible_simulators(school_context) do
    visible_simulator_query(school_context) |> Repo.all()
  end

  def visible_aircrafts(school_context) do
    visible_aircraft_query(school_context) |> Repo.all()
  end

  def visible_aircraft_count(school_context) do
    visible_aircraft_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def get_visible_air_asset(id, school_context) do
    aircraft_query(school_context)
    |> where([a], a.archived == false)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def get_aircraft(id, school_context) do
    aircraft_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def admin_update_aircraft(nil, _attrs), do: {:error, "Aircraft not found."}
  def admin_update_aircraft(aircraft, attrs) do
    aircraft
    |> Aircraft.admin_changeset(attrs)
    |> Repo.update()
  end

  def block_aircraft(id, block, school_context) do
    id
    |> get_aircraft(school_context)
    |> admin_update_aircraft(%{blocked: block})
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

    from_value =
      case NaiveDateTime.from_iso8601(options["from"] || "") do
        {:ok, date} -> date
        _ -> nil
      end

    to_value =
      case NaiveDateTime.from_iso8601(options["to"] || "") do
        {:ok, date} -> date
        _ -> nil
      end

    start_at_after_value =
      case NaiveDateTime.from_iso8601(options["start_at_after"] || "") do
        {:ok, date} -> date
        _ -> nil
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
  end

  def calculate_appointments_duration(appointments) do
    seconds =
      Enum.reduce(appointments, 0, fn appointment, acc ->
        seconds = NaiveDateTime.diff(appointment.end_at, appointment.start_at, :second)
        seconds + acc
      end)

    hours = Integer.floor_div(seconds, 3600) |> to_string
    minutes = Time.add(~T[00:00:00], seconds).minute |> to_string
    hours <> "h" <> "  " <> minutes <> "m"
  end

  def apply_utc_timezone_if_aircraft(changeset, attrs, key, timezone) do
    case Map.get(attrs, key) do
      nil -> changeset
      "" -> changeset
      _value ->
        changeset
        |> apply_utc_timezone(:start_at, timezone)
        |> apply_utc_timezone(:end_at, timezone)
    end
  end

  def apply_utc_timezone(changeset, key, timezone) do
    case get_change(changeset, key) do
      nil -> changeset
      change -> put_change(changeset, key, walltime_to_utc(change, timezone))
    end
  end

  def get_appointment(id, school_context) do
    Appointment
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def get_appointment_dangrous(nil), do: {:error, "id cannot be nil."}
  def get_appointment_dangrous(id) do
    Repo.get(Appointment, id)
    |> case do
        nil -> {:error, "Appiontment with id: #{id} not found."}
        appointment -> {:ok, appointment}
    end
  end

  def insert_or_update_appointment(
    appointment,
    attrs,
    modifying_user,
    school_context
  ) do

    Repo.transaction(fn -> 
      upsert_appointment(appointment, attrs, modifying_user, school_context)
      |> case do
        {:ok, appointment} -> appointment
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  def upsert_appointment(
        appointment,
        attrs,
        modifying_user,
        school_context
      ) do
    school = SchoolScope.get_school(school_context)
    role = List.first(Repo.preload(modifying_user, :roles).roles)

    attrs =
      if Map.get(attrs, :instructor_user_id) in [nil, ""] and Map.get(role, :slug)  == "instructor" do
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

      start_at = get_field(changeset, :start_at) # |> utc_to_walltime(school.timezone)
      end_at = get_field(changeset, :end_at) # |> utc_to_walltime(school.timezone)
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
            permission_slug(:appointment_user, :modify, :personal),
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
              permission_slug(:appointment_instructor, :modify, :personal),
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
            :available -> changeset
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
            :available -> changeset
            other -> 
              add_error(changeset, :room, "is #{other}", status: status)
          end
        else
          changeset
        end
      
      new_aircraft_id = get_change(changeset, :aircraft_id) || get_field(changeset, :aircraft_id)
      new_simulator_id = get_change(changeset, :simulator_id) || get_field(changeset, :simulator_id)

      {should_delete_item, changeset} = 
        if (appointment.aircraft_id != nil && appointment.aircraft_id != new_aircraft_id) or
          (appointment.simulator_id != nil && appointment.simulator_id != new_simulator_id) do
          changeset =
            changeset
            |> Appointment.changeset(%{start_tach_time: nil, end_tach_time: nil, start_hobbs_time: nil, end_hobbs_time: nil}, school.timezone)

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
              else
                send_changed_notifications(appointment, modifying_user)
              end
#            end
          end)

          {:ok, appointment}

        other ->
          if Map.get(temp_changeset, :id) != nil && is_create? == true, do: Repo.delete(temp_changeset), else: nil

          other
      end
    else
      {:error, changeset}
    end
  end

  def get_unavailability(id, school_context) do
    Unavailability
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def get_unavailabilities(options, school_context) do

    from_value =
      case NaiveDateTime.from_iso8601(options["from"] || "") do
        {:ok, date} -> date
        _ -> nil
      end

    to_value =
      case NaiveDateTime.from_iso8601(options["to"] || "") do
        {:ok, date} -> date
        _ -> nil
      end

    start_at_after_value =
      case NaiveDateTime.from_iso8601(options["start_at_after"] || "") do
        {:ok, date} -> date
        _ -> nil
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
  end

  def insert_or_update_unavailability(
        unavailability,
        attrs,
        school_context
      ) do
    school = SchoolScope.get_school(school_context)
    # school_context = Map.put(school_context, :school, school)
    changeset =
      unavailability
      |> SchoolScope.school_changeset(school)
      |> Unavailability.changeset(attrs, school.timezone)

    if changeset.valid? do
      {:ok, _} = apply_action(changeset, :insert)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id) || get_field(changeset, :simulator_id)
      room_id = get_field(changeset, :room_id)

      excluded_unavailability_ids = if unavailability.id, do: [unavailability.id], else: []

      changeset =
        if instructor_user_id do
          start_at = get_field(changeset, :start_at) # utc time for instructor
          end_at = get_field(changeset, :end_at) # utc time for instructor
          status =
            Availability.user_with_permission_status(
              :unavailability,
              permission_slug(:appointment_instructor, :modify, :personal),
              instructor_user_id,
              start_at,
              end_at,
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

      start_at = get_field(changeset, :start_at) #|> utc_to_walltime(school.timezone)
      end_at = get_field(changeset, :end_at) #|> utc_to_walltime(school.timezone)
      
      changeset =
        if aircraft_id do

          status =
            Availability.aircraft_status(
              :unavailability,
              aircraft_id,
              start_at,
              end_at,
              [],
              excluded_unavailability_ids,
              school_context
            )

          case status do
            :available -> changeset
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
              :unavailability,
              room_id,
              start_at,
              end_at,
              excluded_unavailability_ids,
              [],
              school_context
            )

          case status do
            :available -> changeset
            other -> 
              add_error(changeset, :room, "is #{other}", status: status)
          end
        else
          changeset
        end

      Repo.insert_or_update(changeset)
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

  def delete_appointment(id, deleting_user, school_context) do
    appointment =
      get_appointment(id, school_context)
      |> Repo.preload([:user, :instructor_user])

    deleting_user = Repo.preload(deleting_user, :school)
    Appointment.archive(appointment)
    
    Flight.Bills.archive_appointment_invoices(appointment.id)

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

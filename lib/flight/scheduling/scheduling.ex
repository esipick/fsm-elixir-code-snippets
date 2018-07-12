defmodule Flight.Scheduling do
  alias Flight.Scheduling.{
    Aircraft,
    Appointment,
    Availability,
    Inspection,
    DateInspection,
    TachInspection
  }

  alias Flight.Repo
  alias Flight.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Flight.Auth.Permission, only: [permission_slug: 3]
  import Pipe

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

  def visible_aircrafts(school_context) do
    Aircraft
    |> order_by([a], asc: [a.make, a.model, a.tail_number])
    |> SchoolScope.scope_query(school_context)
    |> Repo.all()
  end

  def get_aircraft(id, school_context) do
    Aircraft
    |> where([a], a.id == ^id)
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def admin_update_aircraft(aircraft, attrs) do
    aircraft
    |> Aircraft.admin_changeset(attrs)
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

  def get_appointment(id, school_context) do
    Appointment
    |> SchoolScope.scope_query(school_context)
    |> where([a], a.id == ^id)
    |> Repo.one()
  end

  def insert_or_update_appointment(appointment \\ %Appointment{}, attrs, school_context) do
    changeset =
      appointment
      |> SchoolScope.school_changeset(school_context)
      |> Appointment.changeset(attrs)

    if changeset.valid? do
      {:ok, _} = apply_action(changeset, :insert)
      start_at = get_field(changeset, :start_at)
      end_at = get_field(changeset, :end_at)
      user_id = get_field(changeset, :user_id)
      instructor_user_id = get_field(changeset, :instructor_user_id)
      aircraft_id = get_field(changeset, :aircraft_id)

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
          start_at,
          end_at,
          excluded_appointment_ids,
          school_context
        )

      changeset =
        case status do
          :available -> changeset
          other -> add_error(changeset, :renter, "is #{other}", status: :unavailable)
        end

      # TODO: How to make this dovetale nicely with the calendar_availability endpoint? e.g. instead of querying for
      # appointments directly, could instead query to find all available instructors for the given start/end and then
      # detect whether they're in the list or not
      changeset =
        if instructor_user_id do
          status =
            Availability.user_with_permission_status(
              permission_slug(:appointment_instructor, :modify, :personal),
              instructor_user_id,
              start_at,
              end_at,
              excluded_appointment_ids,
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
              school_context
            )

          case status do
            :available -> changeset
            other -> add_error(changeset, :aircraft, "is #{other}", status: status)
          end
        else
          changeset
        end

      Repo.insert_or_update(changeset)
    else
      {:error, changeset}
    end
  end

  def delete_appointment(id, school_context),
    do: Repo.delete!(get_appointment(id, school_context))

  def get_appointments(options) do
    query = from(a in Appointment)

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

    query
    |> pass_unless(start_at_after_value, &where(&1, [a], a.start_at >= ^start_at_after_value))
    |> pass_unless(
      from_value && to_value,
      &Availability.appointment_overlap_query(&1, from_value, to_value)
    )
    |> pass_unless(user_id_value, &where(&1, [a], a.user_id == ^user_id_value))
    |> pass_unless(aircraft_id_value, &where(&1, [a], a.aircraft_id == ^aircraft_id_value))
    |> pass_unless(
      instructor_user_id_value,
      &from(a in &1, where: a.instructor_user_id == ^instructor_user_id_value)
    )
    |> limit(50)
    |> order_by([a], desc: a.start_at)
    |> Repo.all()
  end
end

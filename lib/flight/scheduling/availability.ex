defmodule Flight.Scheduling.AvailabilityUser do
  defstruct [:user, :status]
end

defmodule Flight.Scheduling.AvailabilityAircraft do
  defstruct [:aircraft, :status]
end

defmodule Flight.Scheduling.Availability do
  alias Flight.Accounts.{Role}

  alias Flight.Scheduling.{
    Aircraft,
    Appointment,
    Unavailability,
    AvailabilityUser,
    AvailabilityAircraft
  }

  alias Flight.Repo
  alias Flight.SchoolScope

  require Ecto.Query
  import Ecto.Query
  import Flight.Auth.Authorization
  import Flight.Auth.Permission, only: [permission_slug: 3]

  @scopes [:all, :appointment, :unavailability]

  def instructor_availability(
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      ) do
    users_with_permission_availability(
      permission_slug(:appointment_instructor, :modify, :personal),
      start_at,
      end_at,
      excluded_appointment_ids,
      excluded_unavailability_ids,
      school_context
    )
  end

  def student_availability(
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      ) do
    users_with_permission_availability(
      permission_slug(:appointment_user, :modify, :personal),
      start_at,
      end_at,
      excluded_appointment_ids,
      excluded_unavailability_ids,
      school_context
    )
  end

  def user_with_permission_status(
        scope \\ :all,
        permission_slug,
        id,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )
      when scope in @scopes do
    user_statuses =
      users_with_permission_availability(
        scope,
        permission_slug,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )

    user_status = Enum.find(user_statuses, &(&1.user.id == id))

    if user_status do
      user_status.status
    else
      :invalid
    end
  end

  def users_with_permission_availability(
        scope \\ :all,
        permission_slug,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )
      when scope in @scopes do
    role_slugs = role_slugs_for_permission_slug(permission_slug)
    roles = from(r in Role, where: r.slug in ^role_slugs) |> Repo.all()

    visible_users = Flight.Accounts.users_with_roles(roles, school_context)

    school = SchoolScope.get_school(school_context)

    appointment_unavailable_user_ids =
      if scope in [:all, :appointment] do
        Appointment
        |> SchoolScope.scope_query(school_context)
        |> select_for_permission_slug(permission_slug)
        |> exclude_appointment_query(excluded_appointment_ids)
        |> overlap_query(
          Flight.Walltime.utc_to_walltime(start_at, school.timezone),
          Flight.Walltime.utc_to_walltime(end_at, school.timezone)
        )
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    unavailability_instructor_ids =
      if scope in [:all, :unavailability] do
        Unavailability
        |> SchoolScope.scope_query(school_context)
        |> select([a], a.instructor_user_id)
        |> overlap_query(
          Flight.Walltime.utc_to_walltime(start_at, school.timezone),
          Flight.Walltime.utc_to_walltime(end_at, school.timezone)
        )
        |> exclude_unavailability_query(excluded_unavailability_ids)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    unavailable_user_ids =
      MapSet.union(appointment_unavailable_user_ids, unavailability_instructor_ids)

    for user <- visible_users do
      if MapSet.member?(unavailable_user_ids, user.id) do
        %AvailabilityUser{user: user, status: :unavailable}
      else
        %AvailabilityUser{user: user, status: :available}
      end
    end
  end

  def select_for_permission_slug(query, permission_slug) do
    instructor_slug = permission_slug(:appointment_instructor, :modify, :personal)

    user_slug = permission_slug(:appointment_user, :modify, :personal)
    student_slug = permission_slug(:appointment_student, :modify, :personal)

    case permission_slug do
      ^instructor_slug ->
        from(a in query, select: a.instructor_user_id)

      slug when slug in [user_slug, student_slug] ->
        from(a in query, select: a.user_id)

      _ ->
        raise "Attempting to request invalid permission slug: #{permission_slug}"
    end
  end

  def aircraft_status(
        scope \\ :all,
        id,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )
      when scope in @scopes do
    aircraft_statuses =
      aircraft_availability(
        scope,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )

    aircraft_status = Enum.find(aircraft_statuses, &(&1.aircraft.id == id))

    if aircraft_status do
      aircraft_status.status
    else
      :invalid
    end
  end

  def aircraft_availability(
        scope \\ :all,
        start_at,
        end_at,
        excluded_appointment_ids,
        excluded_unavailability_ids,
        school_context
      )
      when scope in @scopes do
    visible_aircrafts =
      Aircraft
      |> SchoolScope.scope_query(school_context)
      |> visible_aircraft_query()
      |> Repo.all()
      |> FlightWeb.API.AircraftView.preload()

    school = SchoolScope.get_school(school_context)

    appointment_unavailable_aircraft_ids =
      if scope in [:all, :appointment] do
        Appointment
        |> SchoolScope.scope_query(school_context)
        |> select([a], a.aircraft_id)
        |> overlap_query(
          Flight.Walltime.utc_to_walltime(start_at, school.timezone),
          Flight.Walltime.utc_to_walltime(end_at, school.timezone)
        )
        |> exclude_appointment_query(excluded_appointment_ids)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    unavailability_aircraft_ids =
      if scope in [:all, :unavailability] do
        Unavailability
        |> SchoolScope.scope_query(school_context)
        |> select([a], a.aircraft_id)
        |> overlap_query(
          Flight.Walltime.utc_to_walltime(start_at, school.timezone),
          Flight.Walltime.utc_to_walltime(end_at, school.timezone)
        )
        |> exclude_unavailability_query(excluded_unavailability_ids)
        |> Repo.all()
        |> MapSet.new()
      else
        MapSet.new()
      end

    unavailable_aircraft_ids =
      MapSet.union(appointment_unavailable_aircraft_ids, unavailability_aircraft_ids)

    for aircraft <- visible_aircrafts do
      if MapSet.member?(unavailable_aircraft_ids, aircraft.id) do
        %AvailabilityAircraft{aircraft: aircraft, status: :unavailable}
      else
        %AvailabilityAircraft{aircraft: aircraft, status: :available}
      end
    end
  end

  def visible_user_query(query) do
    from(i in query)
    |> where([i], i.archived == false)
  end

  def visible_aircraft_query(query) do
    from(i in query)
    |> where([i], i.archived == false)
  end

  def overlap_query(query, start_at, end_at) do
    from(
      a in query,
      where:
        (^start_at >= a.start_at and ^start_at < a.end_at) or
          (^end_at > a.start_at and ^end_at <= a.end_at) or
          (^start_at <= a.start_at and ^end_at >= a.end_at)
    )
  end

  def exclude_appointment_query(query, ids) do
    from(a in query, where: a.id not in ^Enum.filter(ids, & &1))
  end

  def exclude_unavailability_query(query, ids) do
    from(a in query, where: a.id not in ^Enum.filter(ids, & &1))
  end
end

defmodule Flight.Scheduling.AvailabilityUser do
  defstruct [:user, :status]
end

defmodule Flight.Scheduling.AvailabilityAircraft do
  defstruct [:aircraft, :status]
end

defmodule Flight.Scheduling.Availability do
  alias Flight.Accounts.{Role}
  alias Flight.Scheduling.{Aircraft, Appointment, AvailabilityUser, AvailabilityAircraft}
  alias Flight.Repo

  require Ecto.Query
  import Ecto.Query
  import Flight.Auth.Authorization
  import Flight.Auth.Permission, only: [permission_slug: 3]

  def instructor_availability(start_at, end_at, excluded_appointment_ids \\ []) do
    users_with_permission_availability(
      permission_slug(:appointment_instructor, :modify, :personal),
      start_at,
      end_at,
      excluded_appointment_ids
    )
  end

  def student_availability(start_at, end_at, excluded_appointment_ids \\ []) do
    users_with_permission_availability(
      permission_slug(:appointment_student, :modify, :personal),
      start_at,
      end_at,
      excluded_appointment_ids
    )
  end

  def user_with_permission_status(
        permission_slug,
        id,
        start_at,
        end_at,
        excluded_appointment_ids \\ []
      ) do
    user_statuses =
      users_with_permission_availability(
        permission_slug,
        start_at,
        end_at,
        excluded_appointment_ids
      )

    user_status = Enum.find(user_statuses, &(&1.user.id == id))

    if user_status do
      user_status.status
    else
      :invalid
    end
  end

  def users_with_permission_availability(
        permission_slug,
        start_at,
        end_at,
        excluded_appointment_ids \\ []
      ) do
    role_slugs = role_slugs_for_permission_slug(permission_slug)
    roles = from(r in Role, where: r.slug in ^role_slugs) |> Repo.all()

    visible_users = Flight.Accounts.users_with_roles(roles)

    unavailable_user_ids =
      Appointment
      |> select_for_permission_slug(permission_slug)
      |> exclude_appointment_query(excluded_appointment_ids)
      |> appointment_overlap_query(start_at, end_at)
      |> Repo.all()
      |> MapSet.new()

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

  def aircraft_status(id, start_at, end_at, excluded_appointment_ids \\ []) do
    aircraft_statuses = aircraft_availability(start_at, end_at, excluded_appointment_ids)

    aircraft_status = Enum.find(aircraft_statuses, &(&1.aircraft.id == id))

    if aircraft_status do
      aircraft_status.status
    else
      :invalid
    end
  end

  def aircraft_availability(start_at, end_at, excluded_appointment_ids \\ []) do
    visible_aircrafts =
      Aircraft
      |> visible_aircraft_query()
      |> Repo.all()

    unavailable_aircraft_ids =
      Appointment
      |> select([a], a.aircraft_id)
      |> appointment_overlap_query(start_at, end_at)
      |> exclude_appointment_query(excluded_appointment_ids)
      |> Repo.all()
      |> MapSet.new()

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
  end

  def visible_aircraft_query(query) do
    from(i in query)
  end

  def appointment_overlap_query(query, start_at, end_at) do
    from(
      a in query,
      where:
        (a.start_at >= ^start_at and a.start_at < ^end_at) or
          (a.end_at >= ^start_at and a.end_at < ^end_at)
    )
  end

  def exclude_appointment_query(query, ids) do
    from(a in query, where: a.id not in ^ids)
  end
end

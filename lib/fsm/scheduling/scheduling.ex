defmodule Fsm.Scheduling do
  alias Flight.Scheduling.{
    Aircraft,
    Availability,
    Inspection,
    DateInspection,
    TachInspection,
    Unavailability,
  }
  alias Fsm.Scheduling.Appointment
  alias Fsm.Scheduling.SchedulingQueries

  alias Flight.Repo
  alias Fsm.SchoolScope
  import Ecto.Changeset
  import Ecto.Query, warn: false
  import Pipe
  import Fsm.Walltime, only: [walltime_to_utc: 2, utc_to_walltime: 2]
  alias Flight.Inspections

  ##
  # List Appointments
  ##
  def list_aircraft_appointments(page, per_page, sort_field, sort_order, params, school_context) do
    filter = Map.put(params, :aircraft_id_is_not_null, true)

    SchedulingQueries.list_appointments_query(page, per_page, sort_field, sort_order, filter, school_context)
    |> Repo.all()
#    |> FlightWeb.API.AppointmentView.preload()
  end

  ##
  # List Appointments
  ##
  def list_appointments(page, per_page, sort_field, sort_order, filter, school_context) do
    resp  =
      SchedulingQueries.list_appointments_query(page, per_page, sort_field, sort_order, filter, school_context)
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

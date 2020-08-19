defmodule FlightWeb.Aircraft.AircraftLogStruct do
  alias __MODULE__
  alias Flight.{Repo, Accounts.User}

  defstruct ~w(
    id user_id aircraft_id user_name school_id school_name action_description updated_at
  )a

  def build(aircraft_log) do
    %AircraftLogStruct{
      id: aircraft_log.id,
      user_id: aircraft_log.user_id,
      aircraft_id: aircraft_log.aircraft_id,
      user_name: aircraft_log.user_name,
      school_id: aircraft_log.school_id,
      school_name: aircraft_log.school_name,
      action_description: aircraft_log.action_description,
      updated_at: aircraft_log.updated_at
    }
  end
end

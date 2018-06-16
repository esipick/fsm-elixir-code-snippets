defmodule FlightWeb.API.AircraftView do
  use FlightWeb, :view

  alias FlightWeb.API.AircraftView

  def render("index.json", %{aircrafts: aircrafts}) do
    %{
      data: render_many(aircrafts, AircraftView, "aircraft.json", as: :aircraft)
    }
  end

  def render("aircraft.json", %{aircraft: aircraft}) do
    %{
      id: aircraft.id,
      make: aircraft.make,
      model: aircraft.model,
      serial_number: aircraft.serial_number,
      equipment: aircraft.equipment,
      ifr_certified: aircraft.ifr_certified,
      simulator: aircraft.simulator,
      tail_number: aircraft.tail_number,
      last_tach_time: aircraft.last_tach_time,
      rate_per_hour: aircraft.rate_per_hour
    }
  end
end

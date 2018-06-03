defmodule FlightWeb.API.AircraftView do
  use FlightWeb, :view

  def render("aircraft.json", %{aircraft: aircraft}) do
    %{
      id: aircraft.id,
      make: aircraft.make,
      model: aircraft.model
    }
  end
end

defmodule FlightWeb.API.AircraftView do
  use FlightWeb, :view

  alias FlightWeb.API.AircraftView

  def render("index.json", %{aircrafts: aircrafts}) do
    %{
      data: render_many(aircrafts, AircraftView, "aircraft.json", as: :aircraft)
    }
  end

  def render("show.json", %{aircraft: aircraft}) do
    %{
      data: render("aircraft.json", aircraft: aircraft)
    }
  end

  def render("aircraft.json", %{aircraft: aircraft}) do
    %{
      id: aircraft.id,
      name: aircraft.name,
      make: aircraft.make,
      model: aircraft.model,
      serial_number: aircraft.serial_number,
      equipment: aircraft.equipment,
      ifr_certified: aircraft.ifr_certified,
      simulator: aircraft.simulator,
      tail_number: aircraft.tail_number,
      last_tach_time: aircraft.last_tach_time,
      last_hobbs_time: aircraft.last_hobbs_time,
      rate_per_hour: aircraft.rate_per_hour,
      block_rate_per_hour: aircraft.block_rate_per_hour,
      blocked: aircraft.blocked,
      airworthiness_certificate: aircraft.airworthiness_certificate,
      registration_certificate_expires_at: aircraft.registration_certificate_expires_at,
      insurance_expires_at: aircraft.insurance_expires_at,
      inspections:
        render_many(aircraft.inspections, AircraftView, "inspection.json", as: :inspection)
    }
  end

  def render("skinny_aircraft.json", %{aircraft: aircraft}) do
    %{
      id: aircraft.id,
      make: aircraft.make,
      model: aircraft.model,
      serial_number: aircraft.serial_number,
      tail_number: aircraft.tail_number,
      last_tach_time: aircraft.last_tach_time,
      last_hobbs_time: aircraft.last_hobbs_time,
      rate_per_hour: aircraft.rate_per_hour,
      block_rate_per_hour: aircraft.block_rate_per_hour
    }
  end

  def render("inspection.json", %{inspection: inspection}) do

    inspection_data = Flight.Repo.preload(inspection, :inspection_data)
    inspection_attachments = Flight.Repo.preload(inspection, :attachments)

    %{
      name: inspection.name,
      type: inspection.type,
      inspection_data: inspection_data,
      inspection_attachments: inspection_attachments
    }
  end

  def render("autocomplete.json", %{aircrafts: aircrafts}) do
    %{data: render_many(aircrafts, AircraftView, "skinny_aircraft.json", as: :aircraft)}
  end

  def preload(aircrafts) do
    Flight.Repo.preload(aircrafts, :inspections)
  end
end

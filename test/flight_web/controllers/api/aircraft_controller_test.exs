defmodule FlightWeb.API.AircraftControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.AircraftView

  describe "GET /api/aircrafts" do
    test "renders aircrafts", %{conn: conn} do
      aircraft1 = aircraft_fixture(%{make: "A"})
      aircraft2 = aircraft_fixture(%{make: "B"})

      json =
        conn
        |> auth(student_fixture())
        |> get("/api/aircrafts")
        |> json_response(200)

      aircrafts =
        [aircraft1, aircraft2]
        |> FlightWeb.API.AircraftView.preload()

      assert json == render_json(AircraftView, "index.json", aircrafts: aircrafts)
    end
  end

  describe "GET /api/aircrafts/:id" do
    test "renders aircrafts", %{conn: conn} do
      aircraft =
        aircraft_fixture()
        |> FlightWeb.API.AircraftView.preload()

      json =
        conn
        |> auth(student_fixture())
        |> get("/api/aircrafts/#{aircraft.id}")
        |> json_response(200)

      assert json == render_json(AircraftView, "show.json", aircraft: aircraft)
    end
  end
end

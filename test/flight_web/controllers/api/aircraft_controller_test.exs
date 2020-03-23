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

  describe "GET /api/aircrafts/autocomplete" do
    test "renders json", %{conn: conn} do
      aircraft1 = aircraft_fixture(%{tail_number: "N45"})
      _aircraft2 = aircraft_fixture()
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/aircrafts/autocomplete?search=N4")
        |> json_response(200)

      assert json == render_json(AircraftView, "autocomplete.json", aircrafts: [aircraft1])
    end

    test "renders error to unauthorized", %{conn: conn} do
      _aircraft1 = aircraft_fixture(%{tail_number: "N45"})
      student = student_fixture()

      conn
      |> auth(student)
      |> get("/api/aircrafts/autocomplete?search=N4")
      |> json_response(401)
    end
  end
end

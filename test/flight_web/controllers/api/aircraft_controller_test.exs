defmodule FlightWeb.API.AircraftControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.AircraftView

  describe "GET /api/aircrafts" do
    test "renders aircrafts", %{conn: conn} do
      aircraft1 = aircraft_fixture()
      aircraft2 = aircraft_fixture()

      json =
        conn
        |> auth(student_fixture())
        |> get("/api/aircrafts")
        |> json_response(200)

      aircrafts = [aircraft1, aircraft2]

      assert json == render_json(AircraftView, "index.json", aircrafts: aircrafts)
    end
  end
end
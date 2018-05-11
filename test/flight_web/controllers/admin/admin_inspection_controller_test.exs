defmodule FlightWeb.Admin.InspectionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "POST /admin/aircrafts/:id/inspections" do
    test "date inspection", %{conn: conn} do
      aircraft = aircraft_fixture()

      payload = %{
        date_inspection: %{
          aircraft_id: aircraft.id,
          name: "Some Good Thing",
          expiration: "3/3/2018"
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/aircrafts/#{aircraft.id}/inspections", payload)

      assert redirected_to(conn) == "/admin/aircrafts/#{aircraft.id}"

      inspection = Flight.Repo.get_by(Flight.Scheduling.Inspection, aircraft_id: aircraft.id)

      assert %Flight.Scheduling.DateInspection{} =
               Flight.Scheduling.Inspection.to_specific(inspection)
    end

    test "tach inspection", %{conn: conn} do
      aircraft = aircraft_fixture()

      payload = %{
        tach_inspection: %{
          aircraft_id: aircraft.id,
          name: "Some Good Thing",
          tach_time: 81089
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/aircrafts/#{aircraft.id}/inspections", payload)

      assert redirected_to(conn) == "/admin/aircrafts/#{aircraft.id}"

      inspection = Flight.Repo.get_by(Flight.Scheduling.Inspection, aircraft_id: aircraft.id)

      assert %Flight.Scheduling.TachInspection{} =
               Flight.Scheduling.Inspection.to_specific(inspection)
    end
  end

  describe "GET /admin/aircrafts/:id/inspections/new" do
    test "no type redirects to type=date", %{conn: conn} do
      aircraft = aircraft_fixture()

      conn =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts/#{aircraft.id}/inspections/new")

      assert redirected_to(conn) == "/admin/aircrafts/#{aircraft.id}/inspections/new?type=date"
    end

    test "renders date", %{conn: conn} do
      aircraft = aircraft_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/aircrafts/#{aircraft.id}/inspections/new?type=date")
      |> html_response(200)
    end

    test "renders tach", %{conn: conn} do
      aircraft = aircraft_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/aircrafts/#{aircraft.id}/inspections/new?type=tach")
      |> html_response(200)
    end
  end

  describe "GET /admin/inspections/:id/edit" do
    test "renders date", %{conn: conn} do
      inspection = date_inspection_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/inspections/#{inspection.id}/edit")
      |> html_response(200)
    end

    test "renders tach", %{conn: conn} do
      inspection = tach_inspection_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/inspections/#{inspection.id}/edit")
      |> html_response(200)
    end
  end

  describe "PUT /admin/inspections/:id" do
    test "date inspection", %{conn: conn} do
      inspection = date_inspection_fixture()

      payload = %{
        inspection: %{
          name: "Some Good Edited Thing",
          expiration: "3/3/2018"
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> put("/admin/inspections/#{inspection.id}", payload)

      assert redirected_to(conn) == "/admin/aircrafts/#{inspection.aircraft.id}"
    end

    test "tach inspection", %{conn: conn} do
      inspection = tach_inspection_fixture()

      payload = %{
        inspection: %{
          name: "Some Good Edited Thing",
          tach_time: 81089
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> put("/admin/inspections/#{inspection.id}", payload)

      assert redirected_to(conn) == "/admin/aircrafts/#{inspection.aircraft.id}"
    end
  end

  describe "DELETE /admin/inspections/:id" do
    test "deletes inspection", %{conn: conn} do
      inspection = date_inspection_fixture(%{name: "This Crazy Thing"})

      conn =
        conn
        |> web_auth_admin()
        |> delete("/admin/inspections/#{inspection.id}")

      refute Flight.Scheduling.get_inspection(inspection.id)

      assert redirected_to(conn) == "/admin/aircrafts/#{inspection.aircraft.id}"
    end
  end
end

defmodule FlightWeb.Admin.AircraftControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Scheduling

  describe "GET /admin/aircrafts" do
    test "renders", %{conn: conn} do
      aircraft = aircraft_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts")
        |> html_response(200)

      assert content =~ aircraft.make
    end

    test "renders search results", %{conn: conn} do
      aircraft = aircraft_fixture(%{ tail_number: "123456" })
      another_aircraft = aircraft_fixture(%{ tail_number: "789123" })

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts?search=789")
        |> html_response(200)

      assert content =~ another_aircraft.tail_number
      refute content =~ aircraft.tail_number
    end
  end

  describe "GET /admin/aircrafts/new" do
    test "renders", %{conn: conn} do
      html =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts/new")
        |> html_response(200)

      assert html =~ "action=\"/admin/aircrafts\""
    end
  end

  describe "POST /admin/aircrafts" do
    test "creates aircraft", %{conn: conn} do
      aircraft = aircraft_fixture()

      new_aircraft =
        %{Map.from_struct(aircraft) | make: "Some Crazy Make Yo"}
        |> Map.delete(:id)

      payload = %{
        data: new_aircraft
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/aircrafts", payload)

      assert %Scheduling.Aircraft{id: id} =
               Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make Yo")

      response_redirected_to(conn, "/admin/aircrafts/#{id}")
    end

    test "fails to create aircraft", %{conn: conn} do
      aircraft = aircraft_fixture()
      new_aircraft = %{Map.from_struct(aircraft) | make: "Some Crazy Make", model: nil}

      payload = %{
        data: new_aircraft
      }

      conn
      |> web_auth_admin()
      |> post("/admin/aircrafts", payload)
      |> html_response(200)

      refute Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make")
    end
  end

  describe "GET /admin/aircrafts/:id" do
    test "renders", %{conn: conn} do
      aircraft = aircraft_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/aircrafts/#{aircraft.id}")
      |> html_response(200)
    end
  end

  describe "GET /admin/aircrafts/:id/edit" do
    test "renders", %{conn: conn} do
      aircraft = aircraft_fixture()

      html =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts/#{aircraft.id}/edit")
        |> html_response(200)

      assert html =~ "action=\"/admin/aircrafts/#{aircraft.id}\""
    end
  end

  describe "PUT /admin/aircrafts/:id" do
    test "updates aircraft", %{conn: conn} do
      aircraft = aircraft_fixture()
      aircraft_payload = %{Map.from_struct(aircraft) | make: "Some Crazy Make"}

      payload = %{
        data: aircraft_payload
      }

      conn
      |> web_auth_admin()
      |> put("/admin/aircrafts/#{aircraft.id}", payload)
      |> response_redirected_to("/admin/aircrafts/#{aircraft.id}")

      assert %Scheduling.Aircraft{} =
               Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make", id: aircraft.id)
    end
  end
end

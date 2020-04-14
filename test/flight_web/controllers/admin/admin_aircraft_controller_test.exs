defmodule FlightWeb.Admin.AircraftControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Scheduling

  describe "GET /admin/aircrafts as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      aircraft = aircraft_fixture(%{}, school)
      another_school = school_fixture(%{name: "another school"})
      another_aircraft = aircraft_fixture(%{make: "another aircraft"}, another_school)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      refute content =~ aircraft.make
      refute content =~ another_aircraft.make

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      content =
        conn
        |> get("/admin/aircrafts")
        |> html_response(200)

      assert content =~ "<th>School</th>"
      assert content =~ aircraft.make
      assert content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
      refute content =~ another_aircraft.make

      refute content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      content =
        conn
        |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
        |> get("/admin/aircrafts")
        |> html_response(200)

      assert content =~ another_aircraft.make

      assert content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      refute content =~ aircraft.make
      refute content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
    end
  end

  describe "GET /admin/aircrafts" do
    test "renders", %{conn: conn} do
      aircraft = aircraft_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      assert content =~ aircraft.make
    end

    test "renders search results", %{conn: conn} do
      aircraft = aircraft_fixture(%{tail_number: "N3456"})
      another_aircraft = aircraft_fixture(%{tail_number: "N9123"})

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts?search=N91")
        |> html_response(200)

      assert content =~ another_aircraft.tail_number
      refute content =~ aircraft.tail_number
    end

    test "renders message when press search with empty field", %{conn: conn} do
      aircraft = aircraft_fixture(%{tail_number: "N3456"})
      another_aircraft = aircraft_fixture(%{tail_number: "N9123"})

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/aircrafts?search=")
        |> html_response(200)

      assert content =~ another_aircraft.tail_number
      assert content =~ aircraft.tail_number
      assert content =~ "Please fill out search field"
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

  describe "GET /admin/aircrafts/:id as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      aircraft = aircraft_fixture(%{}, school)
      another_school = school_fixture()
      another_aircraft = aircraft_fixture(%{}, another_school)

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      conn
      |> get("/admin/aircrafts/#{aircraft.id}")
      |> html_response(200)

      conn
      |> get("/admin/aircrafts/#{another_aircraft.id}")
      |> response_redirected_to("/admin/aircrafts")

      conn
      |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
      |> get("/admin/aircrafts/#{another_aircraft.id}")
      |> html_response(200)
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

    test "show error when aircraft already removed", %{conn: conn} do
      aircraft = aircraft_fixture()
      aircraft_payload = %{Map.from_struct(aircraft) | make: "Some Crazy Make"}

      payload = %{
        data: aircraft_payload
      }

      Flight.Scheduling.archive_aircraft(aircraft)

      conn =
        conn
        |> web_auth_admin()
        |> put("/admin/aircrafts/#{aircraft.id}", payload)
        |> response_redirected_to("/admin/aircrafts")

      html =
        conn
        |> get("/admin/aircrafts")
        |> html_response(200)

      assert get_flash(conn, :error) =~ "Aircraft already removed."
    end
  end
end

defmodule FlightWeb.Admin.SimulatorControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Scheduling

  describe "GET /admin/simulators as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      simulator = simulator_fixture(%{}, school)
      another_school = school_fixture(%{name: "another school"})
      another_simulator = simulator_fixture(%{make: "another simulator"}, another_school)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      refute content =~ simulator.make
      refute content =~ another_simulator.make

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      content =
        conn
        |> get("/admin/simulators")
        |> html_response(200)

      assert content =~ "<th>School</th>"
      assert content =~ simulator.make
      assert content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
      refute content =~ another_simulator.make

      refute content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      content =
        conn
        |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
        |> get("/admin/simulators")
        |> html_response(200)

      assert content =~ another_simulator.make

      assert content =~
               "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

      refute content =~ simulator.make
      refute content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
    end
  end

  describe "GET /admin/simulator" do
    test "renders", %{conn: conn} do
      simulator = simulator_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators")
        |> html_response(200)

      refute content =~ "<th>School</th>"
      assert content =~ simulator.make
    end

    test "renders search results", %{conn: conn} do
      simulator = simulator_fixture(%{name: "N3456"})
      another_simulator = simulator_fixture(%{name: "N9123"})

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators?search=N91")
        |> html_response(200)

      assert content =~ another_simulator.name
      refute content =~ simulator.name
    end

    test "renders message when press search with empty field", %{conn: conn} do
      simulator = simulator_fixture(%{name: "N3456"})
      another_simulator = simulator_fixture(%{name: "N9123"})

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators?search=")
        |> html_response(200)

      assert content =~ another_simulator.name
      assert content =~ simulator.name
      assert content =~ "Please fill out search field"
    end
  end

  describe "GET /admin/simulators/new" do
    test "renders", %{conn: conn} do
      html =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators/new")
        |> html_response(200)

      assert html =~ "action=\"/admin/simulators\""
    end
  end

  describe "POST /admin/simulators" do
    test "creates simulator", %{conn: conn} do
      simulator = simulator_fixture()

      new_simulator =
        %{Map.from_struct(simulator) | make: "Some Crazy Make Yo"}
        |> Map.delete(:id)

      payload = %{
        data: new_simulator
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/simulators", payload)

      assert %Scheduling.Aircraft{id: id} =
               Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make Yo")

      response_redirected_to(conn, "/admin/simulators/#{id}")
    end

    test "fails to create simulator", %{conn: conn} do
      simulator = simulator_fixture()
      new_simulator = %{Map.from_struct(simulator) | make: "Some Crazy Make", model: nil}

      payload = %{
        data: new_simulator
      }

      conn
      |> web_auth_admin()
      |> post("/admin/simulators", payload)
      |> html_response(200)

      refute Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make")
    end
  end

  describe "GET /admin/simulators/:id as superadmin" do
    test "renders", %{conn: conn} do
      school = school_fixture()
      simulator = simulator_fixture(%{}, school)
      another_school = school_fixture()
      another_simulator = simulator_fixture(%{}, another_school)

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      conn
      |> get("/admin/simulators/#{simulator.id}")
      |> html_response(200)

      conn
      |> get("/admin/simulators/#{another_simulator.id}")
      |> response_redirected_to("/admin/simulators")

      conn
      |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
      |> get("/admin/simulators/#{another_simulator.id}")
      |> html_response(200)
    end
  end

  describe "GET /admin/simulators/:id" do
    test "renders", %{conn: conn} do
      simulator = simulator_fixture()

      conn
      |> web_auth_admin()
      |> get("/admin/simulators/#{simulator.id}")
      |> html_response(200)
    end
  end

  describe "GET /admin/simulators/:id/edit" do
    test "renders", %{conn: conn} do
      simulator = simulator_fixture()

      html =
        conn
        |> web_auth_admin()
        |> get("/admin/simulators/#{simulator.id}/edit")
        |> html_response(200)

      assert html =~ "action=\"/admin/simulators/#{simulator.id}\""
    end
  end

  describe "PUT /admin/simulators/:id" do
    test "updates simulator", %{conn: conn} do
      simulator = simulator_fixture()
      simulator_payload = %{Map.from_struct(simulator) | make: "Some Crazy Make"}

      payload = %{
        data: simulator_payload
      }

      conn
      |> web_auth_admin()
      |> put("/admin/simulators/#{simulator.id}", payload)
      |> response_redirected_to("/admin/simulators/#{simulator.id}")

      assert %Scheduling.Aircraft{} =
               Flight.Repo.get_by(Scheduling.Aircraft, make: "Some Crazy Make", id: simulator.id)
    end

    test "show error when simulator already removed", %{conn: conn} do
      simulator = simulator_fixture()
      simulator_payload = %{Map.from_struct(simulator) | make: "Some Crazy Make"}

      payload = %{
        data: simulator_payload
      }

      Flight.Scheduling.archive_aircraft(simulator)

      conn =
        conn
        |> web_auth_admin()
        |> put("/admin/simulators/#{simulator.id}", payload)
        |> response_redirected_to("/admin/simulators")

      conn
      |> get("/admin/simulators")
      |> html_response(200)

      assert get_flash(conn, :error) =~ "Simulator already removed."
    end
  end
end

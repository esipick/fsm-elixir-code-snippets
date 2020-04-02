defmodule FlightWeb.API.SchoolControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /api/school" do
    test "renders school info to admin", %{conn: conn} do
      admin = admin_fixture()

      json =
        conn
        |> auth(admin)
        |> get("/api/school")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.SchoolView,
                 "index.json",
                 school: default_school_fixture()
               )
    end

    test "renders school info to instructor", %{conn: conn} do
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/school")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.SchoolView,
                 "index.json",
                 school: default_school_fixture()
               )
    end

    test "renders school info to dispatcher", %{conn: conn} do
      dispatcher = dispatcher_fixture()

      json =
        conn
        |> auth(dispatcher)
        |> get("/api/school")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.SchoolView,
                 "index.json",
                 school: default_school_fixture()
               )
    end

    test "renders school info to student", %{conn: conn} do
      student = student_fixture()

      json =
        conn
        |> auth(student)
        |> get("/api/school")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.SchoolView,
                 "index.json",
                 school: default_school_fixture()
               )
    end

    test "renders school info to renter", %{conn: conn} do
      renter = user_fixture() |> assign_role("renter")

      json =
        conn
        |> auth(renter)
        |> get("/api/school")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.SchoolView,
                 "index.json",
                 school: default_school_fixture()
               )
    end
  end
end

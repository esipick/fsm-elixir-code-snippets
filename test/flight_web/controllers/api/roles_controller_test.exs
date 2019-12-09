defmodule FlightWeb.API.RolesControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /api/roles" do
    test "renders all roles to admin", %{conn: conn} do
      admin_role = role_fixture(%{slug: "admin"})
      dispatcher_role = role_fixture(%{slug: "dispatcher"})
      instructor_role = role_fixture(%{slug: "instructor"})
      student_role = role_fixture(%{slug: "student"})
      renter_role = role_fixture(%{slug: "renter"})

      admin = admin_fixture()

      json =
        conn
        |> auth(admin)
        |> get("/api/roles")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.RolesView,
                 "index.json",
                 roles: [admin_role, dispatcher_role, instructor_role, student_role, renter_role]
               )
    end

    test "renders reduced roles to instructor", %{conn: conn} do
      _admin_role = role_fixture(%{slug: "admin"})
      _dispatcher_role = role_fixture(%{slug: "dispatcher"})
      instructor_role = role_fixture(%{slug: "instructor"})
      student_role = role_fixture(%{slug: "student"})
      renter_role = role_fixture(%{slug: "renter"})

      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/roles")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.RolesView,
                 "index.json",
                 roles: [instructor_role, student_role, renter_role]
               )
    end
  end
end

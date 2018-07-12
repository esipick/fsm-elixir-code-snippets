defmodule FlightWeb.API.UserControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.UserView

  describe "GET /api/users" do
    test "renders directory", %{conn: conn} do
      user1 = student_fixture()
      _ = instructor_fixture()

      json =
        conn
        |> auth(user1)
        |> get("/api/users?form=directory")
        |> json_response(200)

      users = Flight.Repo.preload(Flight.Accounts.get_users(default_school_fixture()), :roles)

      assert json ==
               render_json(
                 UserView,
                 "index.json",
                 users: users,
                 form: "directory_user.json"
               )
    end
  end

  describe "GET /api/users/:id" do
    test "renders json", %{conn: conn} do
      user =
        student_fixture()
        |> Flight.Repo.preload([:roles, :flyer_certificates])

      json =
        conn
        |> auth(user)
        |> get("/api/users/#{user.id}")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 if student requesting other student", %{conn: conn} do
      student = student_fixture()
      other_student = student_fixture()

      conn
      |> auth(other_student)
      |> get("/api/users/#{student.id}")
      |> response(401)
    end

    test "401 if no auth", %{conn: conn} do
      conn
      |> get("/api/users/4")
      |> response(401)
    end
  end

  describe "PUT /api/users/:id" do
    test "renders json", %{conn: conn} do
      user =
        student_fixture(%{first_name: "Justin"})
        |> Flight.Repo.preload(:flyer_certificates)

      assert user.flyer_certificates == []

      cert = flyer_certificate_fixture()

      updates = %{
        first_name: "Alex",
        flyer_certificates: [cert.slug]
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(200)

      user =
        Flight.Repo.get!(Flight.Accounts.User, user.id)
        |> Flight.Repo.preload([:roles, :flyer_certificates])

      assert user.first_name == "Alex"
      assert user.flyer_certificates == [cert]

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 if no auth", %{conn: conn} do
      conn
      |> put("/api/users/4")
      |> response(401)
    end

    test "401 if other user", %{conn: conn} do
      user1 = student_fixture()
      user2 = student_fixture()

      conn
      |> auth(user1)
      |> put("/api/users/#{user2.id}")
      |> response(401)
    end
  end

  describe "GET /api/users/:id/form_items" do
    test "renders", %{conn: conn} do
      user = student_fixture()

      json =
        conn
        |> auth(user)
        |> get("/api/users/#{user.id}/form_items")
        |> json_response(200)

      items =
        user
        |> Flight.Accounts.editable_fields()
        |> Enum.map(&FlightWeb.UserForm.item(user, &1))

      assert json ==
               render_json(
                 UserView,
                 "form_items.json",
                 form_items: items
               )
    end
  end
end

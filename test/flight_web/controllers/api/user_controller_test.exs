defmodule FlightWeb.API.UserControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.UserView

  describe "GET /api/users" do
    test "renders directory", %{conn: conn} do
      user1 = student_fixture()
      user2 = instructor_fixture()

      json =
        conn
        |> auth(user1)
        |> get("/api/users?form=directory")
        |> json_response(200)

      users = Flight.Repo.preload([user1, user2], :roles)

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
        user_fixture()
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

    test "401 if no auth", %{conn: conn} do
      conn
      |> get("/api/users/4")
      |> response(401)
    end
  end

  describe "PUT /api/users/:id" do
    test "renders json", %{conn: conn} do
      user = student_fixture(%{first_name: "Justin"})

      updates = %{
        first_name: "Alex"
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

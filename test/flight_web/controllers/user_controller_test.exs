defmodule FlightWeb.UserControllerTest do
  use FlightWeb.ConnCase

  describe "GET /api/users/:id" do
    test "renders json", %{conn: conn} do
      user = user_fixture()

      json =
        conn
        |> auth(user)
        |> get("/api/users/#{user.id}")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.UserView,
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
      user = user_fixture(%{first_name: "Justin"})

      updates = %{
        first_name: "Alex"
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(200)

      user = Flight.Repo.get!(Flight.Accounts.User, user.id)

      assert user.first_name == "Alex"

      assert json ==
               render_json(
                 FlightWeb.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 if no auth", %{conn: conn} do
      conn
      |> put("/api/users/4")
      |> response(401)
    end
  end
end

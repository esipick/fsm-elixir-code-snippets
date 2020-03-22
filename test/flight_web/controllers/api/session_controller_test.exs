defmodule FlightWeb.API.SessionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "POST /api/login" do
    test "logs in successfully", %{conn: conn} do
      user =
        user_fixture(%{email: "food@bard.com", password: "oh hey there"})
        |> FlightWeb.API.UserView.show_preload()

      json =
        conn
        |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
        |> json_response(200)

      assert {:ok, user_id, _token} =
               FlightWeb.AuthenticateApiUser.user_id_from_token(json["token"])

      assert user_id == user.id

      assert json ==
               render_json(
                 FlightWeb.API.SessionView,
                 "login.json",
                 user: user,
                 token: json["token"]
               )
    end

    test "401 if user archived", %{conn: conn} do
      user =
        user_fixture(%{email: "food@bard.com", password: "oh hey there"})
        |> FlightWeb.API.UserView.show_preload()
      Flight.Accounts.archive_user(user)

      json =
        conn
        |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
        |> json_response(401)

      assert json == %{
        "human_errors" => ["Account is suspended. Please contact your school administrator to reinstate it."]
      }
    end

    test "401 if incorrect password", %{conn: conn} do
      _ = user_fixture(%{email: "food@bard.com", password: "oh hey there"})

      conn
      |> post("/api/login", %{email: "food@bard.com", password: "oh hey there sam"})
      |> json_response(401)
    end

    test "401 if incorrect email", %{conn: conn} do
      _ = user_fixture(%{email: "food@bard.commers", password: "oh hey there"})

      conn
      |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
      |> json_response(401)
    end

    test "401 after deleting the user", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> auth(user)

      conn
      |> get("/api/invoices/appointments")
      |> json_response(200)

      Flight.Accounts.archive_user(user)

      conn
      |> get("/api/invoices/appointments")
      |> response(401)
    end
  end
end

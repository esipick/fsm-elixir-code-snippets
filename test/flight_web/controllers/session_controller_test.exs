defmodule FlightWeb.SessionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "POST /api/login" do
    test "logs in successfully", %{conn: conn} do
      user = user_fixture(%{email: "food@bard.com", password: "oh hey there"})

      json =
        conn
        |> post("/api/login", %{email: "food@bard.com", password: "oh hey there"})
        |> json_response(200)

      assert {:ok, user_id} = FlightWeb.AuthenticateUser.user_id_from_token(json["token"])
      assert user_id == user.id

      assert json ==
               render_json(FlightWeb.SessionView, "login.json", user: user, token: json["token"])
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
  end
end

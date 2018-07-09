defmodule FlightWeb.API.PushTokenControllerTest do
  use FlightWeb.ConnCase

  require Ecto.Query
  import Ecto.Query
  import Flight.NotificationsFixtures

  describe "POST /api/users/:id/push_tokens" do
    @tag :integration
    test "creates device token", %{conn: conn} do
      user = student_fixture()
      token_string = Flight.Random.hex(15)

      conn
      |> auth(user)
      |> post("/api/users/#{user.id}/push_tokens", %{
        data: %{token: token_string, platform: "ios"}
      })
      |> response(204)

      token =
        Flight.Repo.one(from(t in Flight.Notifications.PushToken, where: t.user_id == ^user.id))

      assert token.token == token_string
      assert String.starts_with?(token.endpoint_arn, "arn")
    end

    test "doesn't create new token if one already exists with given token", %{conn: conn} do
      token_string = Flight.Random.hex(15)
      token = push_token_fixture(%{token: token_string})

      conn
      |> auth(token.user)
      |> post("/api/users/#{token.user.id}/push_tokens", %{
        data: %{token: token_string, platform: "ios"}
      })
      |> response(204)

      assert Flight.Repo.one(
               from(t in Flight.Notifications.PushToken, where: t.user_id == ^token.user.id)
             ).id == token.id
    end

    test "ownership of existing token is transferred to the requesting user", %{conn: conn} do
      token_string = Flight.Random.hex(15)
      token = push_token_fixture(%{token: token_string})
      other_user = student_fixture()

      conn
      |> auth(other_user)
      |> post("/api/users/#{other_user.id}/push_tokens", %{
        data: %{token: token_string, platform: "ios"}
      })
      |> response(204)

      assert Flight.Repo.one(
               from(t in Flight.Notifications.PushToken, where: t.user_id == ^token.user.id)
             )
             |> is_nil()

      assert Flight.Repo.one(
               from(t in Flight.Notifications.PushToken, where: t.user_id == ^other_user.id)
             ).id == token.id
    end

    test "401 if not requesting user's token", %{conn: conn} do
      user = student_fixture()
      other_user = student_fixture()

      conn
      |> auth(user)
      |> post("/api/users/#{other_user.id}/push_tokens")
      |> response(401)
    end
  end
end

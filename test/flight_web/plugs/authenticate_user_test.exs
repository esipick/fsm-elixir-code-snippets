defmodule FlightWeb.AuthenticateUserTest do
  use FlightWeb.ConnCase, async: true

  alias FlightWeb.AuthenticateUser

  test "sets current user if valid auth token", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> put_req_header("authorization", AuthenticateUser.token(user))
      |> AuthenticateUser.call([])

    assert conn.assigns.current_user.id == user.id
  end

  test "sets current user if valid auth token passed as option", %{conn: conn} do
    user = user_fixture()
    conn = %{conn | query_params: %{"token" => AuthenticateUser.token(user)}}

    conn =
      conn
      |> AuthenticateUser.call([])

    assert conn.assigns.current_user.id == user.id
  end

  test "401 if token is invalid", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "blah blah")
      |> AuthenticateUser.call([])

    assert conn.status == 401
  end

  test "401 if token is missing", %{conn: conn} do
    conn =
      conn
      |> AuthenticateUser.call([])

    assert conn.status == 401
  end

  # Potentially a thing later
  # test "401 if user is blocked", %{conn: conn} do
  #   user = user_fixture(%{blocked: true})
  #
  #   conn =
  #     conn
  #     |> auth(user)
  #     |> AuthenticateUser.call([])
  #
  #   assert conn.status == 401
  # end
end

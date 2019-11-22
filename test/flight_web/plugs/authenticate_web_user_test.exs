defmodule FlightWeb.AuthenticateWebUserTest do
  use FlightWeb.ConnCase, async: true

  alias FlightWeb.AuthenticateWebUser

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "yadayada",
             signing_salt: "yadayada"
           )

  setup opts do
    conn =
      opts.conn
      |> Map.put(
        :secret_key_base,
        String.duplicate("foobar", 12)
      )
      |> Plug.Session.call(@session)
      |> fetch_session()

    {:ok, %{opts | conn: conn}}
  end

  test "log_in sets admin_user_id", %{conn: conn} do
    user_id =
      conn
      |> AuthenticateWebUser.log_in(3)
      |> get_session(:user_id)

    assert user_id == 3
  end

  test "log_out unsets admin_user_id", %{conn: conn} do
    user_id =
      conn
      |> AuthenticateWebUser.log_in(3)
      |> AuthenticateWebUser.log_out()
      |> get_session(:user_id)

    assert is_nil(user_id)
  end

  test "sets current user if logged in", %{conn: conn} do
    user = user_fixture() |> assign_role("admin")

    conn =
      conn
      |> AuthenticateWebUser.log_in(user.id)
      |> AuthenticateWebUser.call(roles: ["admin"])

    assert conn.assigns.current_user.id == user.id
  end

  test "redirect if user doesn't have roles", %{conn: conn} do
    user = user_fixture() |> assign_role("admin")

    conn =
      conn
      |> AuthenticateWebUser.log_in(user.id + 1)
      |> AuthenticateWebUser.call(roles: ["student"])

    assert redirected_to(conn) == "/login"
    refute get_session(conn, :user_id)
  end

  test "redirect if id is invalid", %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> AuthenticateWebUser.log_in(user.id + 1)
      |> AuthenticateWebUser.call([])

    assert redirected_to(conn) == "/login"
    refute get_session(conn, :user_id)
  end

  test "redirect if token is missing", %{conn: conn} do
    conn =
      conn
      |> AuthenticateWebUser.call([])

    assert redirected_to(conn) == "/login"
    assert conn.halted
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

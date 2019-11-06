defmodule Flight.ConnCaseHelpers do
  def render_json(module, template, assigns) do
    assigns = Map.new(assigns)

    module.render(template, assigns)
    |> Poison.encode!()
    |> Poison.decode!()
  end

  def auth(conn, %Flight.Accounts.User{} = user) do
    Plug.Conn.put_req_header(conn, "authorization", FlightWeb.AuthenticateApiUser.token(user))
  end

  def web_auth(conn, %Flight.Accounts.User{} = user) do
    conn
    |> Plug.Test.init_test_session([])
    |> Plug.Conn.put_session(:user_id, user.id)
  end

  def web_auth_admin(conn, user \\ Flight.AccountsFixtures.admin_fixture()) do
    web_auth(conn, user)
  end

  def web_auth_dispatcher(conn, user \\ Flight.AccountsFixtures.dispatcher_fixture()) do
    web_auth(conn, user)
  end

  defmacro redirected_to_login(conn) do
    quote do
      assert redirected_to(unquote(conn)) == "/admin/login"
      unquote(conn)
    end
  end

  defmacro response_redirected_to(conn, path) do
    quote do
      assert redirected_to(unquote(conn)) == unquote(path)
      unquote(conn)
    end
  end
end

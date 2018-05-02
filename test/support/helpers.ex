defmodule Flight.TestHelpers do
  def render_json(module, template, assigns) do
    assigns = Map.new(assigns)

    module.render(template, assigns)
    |> Poison.encode!()
    |> Poison.decode!()
  end

  def auth(conn, %Flight.Accounts.User{} = user) do
    Plug.Conn.put_req_header(conn, "authorization", FlightWeb.AuthenticateApiUser.token(user))
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

defmodule Flight.TestHelpers do
  def render_json(module, template, assigns) do
    assigns = Map.new(assigns)

    module.render(template, assigns)
    |> Poison.encode!()
    |> Poison.decode!()
  end

  def auth(conn, %Flight.Accounts.User{} = user) do
    Plug.Conn.put_req_header(conn, "authorization", FlightWeb.AuthenticateUser.token(user))
  end
end

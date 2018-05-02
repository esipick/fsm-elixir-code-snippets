defmodule FlightWeb.AuthenticateWebUser do
  import Plug.Conn

  require Ecto.Query

  def init(opts) do
    opts
  end

  def call(conn, opts \\ [roles: []]) do
    case user_from_session(conn, Keyword.get(opts, :roles)) do
      {:ok, user} ->
        assign(conn, :current_user, user)

      {:error, code} ->
        conn = if code == :user_not_found, do: log_out(conn), else: conn

        conn
        |> Phoenix.Controller.redirect(to: "/admin/login")
        |> halt()
    end
  end

  def user_from_session(conn, roles) do
    if roles && length(roles) == 0 do
      raise "Roles list empty when authenticating user"
    end

    id = get_session(conn, :user_id)

    if id do
      user =
        if roles do
          Flight.Accounts.get_user(id, roles)
        else
          Flight.Accounts.get_user(id)
        end

      if user do
        {:ok, user}
      else
        {:error, :user_not_found}
      end
    else
      {:error, :no_session_user_id}
    end
  end

  def log_in(conn, user_id) do
    put_session(conn, :user_id, user_id)
  end

  def log_out(conn) do
    delete_session(conn, :user_id)
  end
end

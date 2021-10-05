defmodule FlightWeb.AuthenticateWebUser do
  import Plug.Conn

  require Ecto.Query
  import Ecto.Query

  def init(opts) do
    opts
  end

  def call(conn, opts \\ [roles: []]) do
    case user_from_session(conn, Keyword.get(opts, :roles)) do
      {:ok, user} ->
        user =
          user
          |> Flight.Repo.preload([:school])

        app_version = Fsm.AppVersions.get_app_version() |> Map.get(:web_version)

        conn
        |> assign(:current_user, user)
        |> assign(:version, app_version)

      {:error, code} ->
        conn = if code == :user_not_found, do: log_out(conn), else: conn

        conn
        |> Phoenix.Controller.redirect(to: "/login")
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
          get_user(id, roles)
        else
          get_user(id)
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

  defp get_user(id) do
    Flight.Accounts.dangerous_get_active_user(id)
  end

  defp get_user(id, roles) do
    from(
      u in Flight.Accounts.User,
      distinct: u.id,
      inner_join: r in assoc(u, :roles),
      where: r.slug in ^roles,
      where: u.archived == false,
      where: u.id == ^id
    )
    |> Flight.Repo.one()
  end

  def log_in(conn, user_id) do
    put_session(conn, :user_id, user_id)
  end

  def log_out(conn) do
    #logout from LMS
    user = Flight.Accounts.dangerous_get_user(get_session(conn, :user_id))
    Flight.Utils.logout_from_lms(user.id)
    delete_session(conn, :user_id)
  end
end

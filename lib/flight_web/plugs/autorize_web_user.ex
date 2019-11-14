defmodule FlightWeb.AuthorizeWebUser do
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

        assign(conn, :current_user, user)

      {:error, code} ->
        reject(conn, code)
    end
  end

  def reject(conn, code) do
    conn = if code == :user_not_found, do: log_out(conn), else: conn

    conn
    |> Phoenix.Controller.redirect(to: "/login")
    |> halt()
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
    delete_session(conn, :user_id)
  end
end

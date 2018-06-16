defmodule FlightWeb.API.UserController do
  use FlightWeb, :controller

  alias Flight.Accounts
  alias Flight.Auth.Permission

  plug(FlightWeb.AuthenticateApiUser)
  plug(:get_user when action in [:show, :update, :form_items])
  plug(:authorize_modify when action in [:update, :form_items])

  def index(conn, %{"form" => form}) do
    result =
      case form do
        "directory" ->
          users =
            Accounts.get_users()
            |> Flight.Repo.preload(:roles)

          {:ok, users, "directory_user.json"}

        _ ->
          :error
      end

    case result do
      {:ok, users, form} ->
        render(conn, "index.json", users: users, form: form)

      :error ->
        conn
        |> put_status(400)
        |> json(%{error: %{message: "Invalid form"}})
    end
  end

  def show(conn, _params) do
    user =
      conn.assigns.user
      |> Flight.Repo.preload([:roles, :flyer_certificates])

    render(conn, "show.json", user: user)
  end

  def update(conn, params) do
    with {:ok, user} <- Accounts.update_user(conn.assigns.user, params["data"]) do
      user =
        user
        |> Flight.Repo.preload([:roles, :flyer_certificates])

      render(conn, "show.json", user: user)
    end
  end

  def form_items(conn, _params) do
    items =
      conn.assigns.user
      |> Accounts.editable_fields()
      |> Enum.map(&FlightWeb.UserForm.item(conn.assigns.user, &1))

    render(conn, "form_items.json", form_items: items)
  end

  def authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :modify, {:personal, conn.assigns.user})
    ])
  end

  defp get_user(conn, _) do
    assign(conn, :user, Accounts.get_user!(conn.params["id"] || conn.params["user_id"]))
  end
end

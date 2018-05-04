defmodule FlightWeb.Admin.UserController do
  use FlightWeb, :controller

  alias Flight.Accounts
  plug(:get_user when action in [:show, :edit, :update])

  def index(conn, %{"role" => role_slug}) do
    render(conn, "index.html", data: FlightWeb.Admin.UserListData.build(role_slug))
  end

  def show(conn, _params) do
    render(conn, "show.html", user: conn.assigns.requested_user)
  end

  def edit(conn, _params) do
    render(
      conn,
      "edit.html",
      user: conn.assigns.requested_user,
      changeset: Accounts.User.create_changeset(conn.assigns.requested_user, %{})
    )
  end

  def update(conn, %{"user" => user_form} = params) do
    case Accounts.update_user_profile(
           conn.assigns.requested_user,
           user_form,
           Map.keys(params["role_slugs"] || %{}),
           Map.keys(params["flyer_certificate_slugs"] || %{})
         ) do
      {:ok, user} ->
        redirect(conn, to: "/admin/users/#{user.id}")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          user: conn.assigns.requested_user,
          changeset: changeset
        )
    end
  end

  defp get_user(conn, _) do
    user =
      conn.params["id"]
      |> Accounts.get_user!()
      |> Flight.Repo.preload([:roles, :flyer_certificates])

    conn
    |> assign(:requested_user, user)
  end
end

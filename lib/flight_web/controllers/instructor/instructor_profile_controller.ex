defmodule FlightWeb.Instructor.ProfileController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def show(conn, _) do
    user = Flight.Repo.preload(conn.assigns.current_user, [:roles, :flyer_certificates])
    render(conn, "show.html", user: user)
  end

  def edit(conn, _) do
    user = Flight.Repo.preload(conn.assigns.current_user, [:roles, :flyer_certificates])

    render(
      conn,
      "edit.html",
      user: user,
      changeset: Accounts.User.create_changeset(user, %{})
    )
  end

  def update(conn, params) do
    user_form =
      if String.trim(params["user"]["password"]) == "" do
        Map.delete(params["user"], "password")
      else
        params["user"]
      end

    user = Flight.Repo.preload(conn.assigns.current_user, [:roles, :flyer_certificates])

    case Accounts.regular_user_update_profile(user, user_form) do
      {:ok, _} ->
        redirect(conn, to: "/instructor/profile")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          user: user,
          changeset: changeset
        )
    end
  end
end

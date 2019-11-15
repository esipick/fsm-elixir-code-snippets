defmodule FlightWeb.Student.ProfileController do
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

  def update(conn, %{"user" => user_form} = params) do
    user_form = if String.trim(params["user"]["password"]) == "" do
      Map.delete(params["user"], "password")
    else
      params["user"]
    end
    require IEx; IEx.pry()
    user = Flight.Repo.preload(conn.assigns.current_user, [:roles, :flyer_certificates])

    case Accounts.student_update_own_profile(user, user_form) do
      {:ok, user} ->
        redirect(conn, to: "/student/profile")

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

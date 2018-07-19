defmodule FlightWeb.Admin.SettingsController do
  use FlightWeb, :controller

  alias Flight.Accounts

  plug(:get_school)

  def show(conn, %{"tab" => "contact"}) do
    changeset = Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(
      conn,
      "show.html",
      tab: :contact,
      school: conn.assigns.school,
      changeset: changeset
    )
  end

  def show(conn, %{"tab" => "billing"}) do
    render(conn, "show.html", tab: :billing, school: conn.assigns.school)
  end

  def show(conn, _) do
    changeset = Flight.Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(
      conn,
      "show.html",
      tab: :school,
      school: conn.assigns.school,
      changeset: changeset
    )
  end

  def update(conn, %{"data" => school_params, "redirect_tab" => redirect_tab}) do
    case Accounts.admin_update_school(conn.assigns.school, school_params) do
      {:ok, _school} ->
        redirect_append =
          case redirect_tab do
            "school" -> ""
            "contact" -> "?tab=contact"
          end

        conn
        |> put_flash(:success, "Successfully updated settings.")
        |> redirect(to: "/admin/settings#{redirect_append}")

      {:error, changeset} ->
        tab =
          case redirect_tab do
            "school" -> :school
            "contact" -> :contact
          end

        render(
          conn,
          "show.html",
          tab: tab,
          school: conn.assigns.school,
          changeset: changeset
        )
    end
  end

  def get_school(conn, _) do
    assign(conn, :school, Flight.Repo.preload(conn.assigns.current_user.school, :stripe_account))
  end
end

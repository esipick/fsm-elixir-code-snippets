defmodule FlightWeb.Admin.SettingsController do
  use FlightWeb, :controller

  import Flight.Repo
  alias Flight.Accounts
  alias Flight.Auth.Permission

  plug(:get_school)
  plug(:authorize_admin when action in [:show])

  def show(conn, %{"tab" => "contact"}) do
    changeset = Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(
      conn,
      "show.html",
      tab: :contact,
      school: conn.assigns.school,
      changeset: changeset,
      hide_school_info: true
    )
  end

  def show(conn, %{"tab" => "billing"}) do
    render(conn, "show.html", tab: :billing, school: conn.assigns.school, hide_school_info: true)
  end

  def show(conn, _) do
    changeset = Flight.Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(
      conn,
      "show.html",
      tab: :school,
      school: conn.assigns.school,
      changeset: changeset,
      hide_school_info: true
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
        |> redirect(to: conn.request_path <> redirect_append)

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
          changeset: changeset,
          hide_school_info: true
        )
    end
  end

  def get_school(%{params: %{"id" => id}} = conn, _) do
    if Flight.Accounts.is_superadmin?(conn.assigns.current_user) do
      if school = Flight.Accounts.get_school(id) |> preload(:stripe_account) do
        conn
        |> assign(:school, school)
      else
        conn
        |> put_flash(:warning, "Unknown school.")
        |> redirect(to: "/admin/schools")
        |> halt()
      end
    else
      conn
      |> redirect(to: "/admin/settings")
      |> halt()
    end
  end

  def get_school(%{assigns: %{current_user: %{school: school}}} = conn, _) do
    conn
    |> assign(:school, Flight.Repo.preload(school, :stripe_account))
  end

  defp authorize_admin(conn, _) do
    if conn.query_params["tab"] == "billing" do
      redirect_unless_user_can?(conn, [Permission.new(:billing_settings, :modify, :all)])
    else
      conn
    end
  end
end

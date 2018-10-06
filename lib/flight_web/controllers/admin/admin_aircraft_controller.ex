defmodule FlightWeb.Admin.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling

  plug(:get_aircraft when action in [:show, :edit, :update])

  def create(conn, %{"data" => aircraft_data}) do
    case Scheduling.admin_create_aircraft(aircraft_data, conn) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully created aircraft.")
        |> redirect(to: "/admin/aircrafts/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def new(conn, _params) do
    conn
    |> render(
      "new.html",
      changeset: Scheduling.Aircraft.admin_changeset(%Scheduling.Aircraft{}, %{})
    )
  end

  def show(conn, _params) do
    aircraft = Flight.Repo.preload(conn.assigns.aircraft, :inspections)

    conn
    |> render("show.html", aircraft: aircraft)
  end

  def index(conn, _params) do
    conn
    |> render("index.html", aircrafts: Scheduling.visible_aircrafts(conn))
  end

  def edit(conn, _params) do
    conn
    |> render(
      "edit.html",
      changeset: Scheduling.Aircraft.admin_changeset(conn.assigns.aircraft, %{})
    )
  end

  def update(conn, %{"data" => aircraft_data}) do
    case Scheduling.admin_update_aircraft(conn.assigns.aircraft, aircraft_data) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully updated aircraft.")
        |> redirect(to: "/admin/aircrafts/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    aircraft = Flight.Scheduling.get_aircraft(id, conn)

    Flight.Scheduling.archive_aircraft(aircraft)

    conn
    |> put_flash(:success, "Aircraft successfully archived.")
    |> redirect(to: "/admin/aircrafts")
  end

  defp get_aircraft(conn, _) do
    aircraft = Scheduling.get_aircraft(conn.params["id"] || conn.params["aircraft_id"], conn)

    if aircraft do
      assign(conn, :aircraft, aircraft)
    else
      conn
      |> put_flash(:warning, "Unknown aircraft.")
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end
end

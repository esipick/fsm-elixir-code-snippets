defmodule FlightWeb.Admin.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling

  plug(:get_aircraft when action in [:show, :edit, :update])

  def create(conn, %{"data" => aircraft_data}) do
    case Scheduling.create_aircraft(aircraft_data) do
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
    |> render("new.html", changeset: Scheduling.Aircraft.changeset(%Scheduling.Aircraft{}, %{}))
  end

  def show(conn, _params) do
    conn
    |> render("show.html", aircraft: conn.assigns.aircraft)
  end

  def index(conn, _params) do
    conn
    |> render("index.html", aircrafts: Scheduling.visible_aircrafts())
  end

  def edit(conn, _params) do
    conn
    |> render("edit.html", changeset: Scheduling.Aircraft.changeset(conn.assigns.aircraft, %{}))
  end

  def update(conn, %{"data" => aircraft_data}) do
    case Scheduling.update_aircraft(conn.assigns.aircraft, aircraft_data) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully updated aircraft.")
        |> redirect(to: "/admin/aircrafts/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  defp get_aircraft(conn, _) do
    aircraft = Scheduling.get_aircraft(conn.params["id"] || conn.params["aircraft_id"])

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

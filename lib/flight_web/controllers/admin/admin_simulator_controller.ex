defmodule FlightWeb.Admin.SimulatorController do
  use FlightWeb, :controller

  alias Flight.Scheduling
  alias Flight.Scheduling.Aircraft
  alias Flight.Repo

  plug(:get_aircraft when action in [:show, :edit, :update, :delete])

  def create(conn, %{"data" => aircraft_data}) do
    case Scheduling.admin_create_simulator(aircraft_data, conn) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully created simulator.")
        |> redirect(to: "/admin/simulators/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def new(conn, _params) do
    conn
    |> render(
      "new.html",
      changeset: Aircraft.admin_changeset(%Aircraft{}, %{})
    )
  end

  def show(conn, _params) do
    aircraft = Repo.preload(conn.assigns.aircraft, :inspections)

    conn
    |> render("show.html", simulator: aircraft, skip_shool_select: true)
  end

  def index(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.SimulatorListData.build(conn, page_params, search_term)
    message = params["search"] && set_message(params["search"])

    conn
    |> render("index.html", data: data, message: message, tab: :simulator)
  end

  def edit(conn, _params) do
    conn
    |> render(
      "edit.html",
      simulator: conn.assigns.aircraft,
      changeset: Aircraft.admin_changeset(conn.assigns.aircraft, %{}),
      skip_shool_select: true
    )
  end

  def update(conn, %{"data" => aircraft_data}) do
    case Scheduling.admin_update_aircraft(conn.assigns.aircraft, aircraft_data) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully updated aircraft.")
        |> redirect(to: "/admin/simulators/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    Scheduling.archive_aircraft(conn.assigns.aircraft)

    conn
    |> put_flash(:success, "Simulator successfully archived.")
    |> redirect(to: "/admin/simulators")
  end

  defp get_aircraft(conn, _) do
    id = conn.params["id"] || conn.params["simulator_id"] || conn.params["aircraft_id"]
    aircraft = Scheduling.get_aircraft(id, conn)

    cond do
      aircraft && !aircraft.archived ->
        assign(conn, :aircraft, aircraft)

      aircraft && aircraft.archived ->
        conn
        |> put_flash(:error, "Simulator already removed.")
        |> redirect(to: "/admin/simulators")
        |> halt()

      true ->
        conn
        |> put_flash(:error, "Unknown simulator.")
        |> redirect(to: "/admin/simulators")
        |> halt()
    end
  end

  defp set_message(search_param) do
    if String.trim(search_param) == "" do
      "Please fill out search field"
    end
  end
end

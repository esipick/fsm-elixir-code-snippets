defmodule FlightWeb.Admin.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling
  alias Flight.Scheduling.Aircraft
  alias Flight.Repo

  import FlightWeb.Admin.AssetsHelper

  plug(:get_aircraft when action in [:logs, :show, :edit, :update, :delete])

  def create(conn, %{"data" => aircraft_data}) do
    redirect_to = get_redirect_param(aircraft_data)

    case Scheduling.admin_create_aircraft(aircraft_data, conn) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully created aircraft.")
        |> redirect(to: redirect_to || "/admin/aircrafts/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset, redirect_to: redirect_to)
    end
  end

  def new(conn, params) do
    conn
    |> render(
      "new.html",
      redirect_to: params["redirect_to"],
      changeset: Aircraft.admin_changeset(%Aircraft{}, %{})
    )
  end

  def show(conn, _params) do
    aircraft = Repo.preload(conn.assigns.aircraft, :inspections)

    conn
    |> render("show.html", aircraft: aircraft, skip_shool_select: true)
  end
require Logger
  def logs(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftLogsListData.build(conn, page_params, search_term)
    # Logger.info fn -> "data: #{inspect data}" end
    message = params["search"] && set_message(params["search"])

    aircraft = Repo.preload(conn.assigns.aircraft, :audit_logs)

    conn
    |> render("logs.html", aircraft: aircraft, data: data, message: message)
  end

  def index(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftListData.build(conn, page_params, search_term)
    message = params["search"] && set_message(params["search"])

    conn
    |> render("index.html", data: data, message: message, tab: :aircraft)
  end

  def edit(conn, params) do
    conn
    |> render(
      "edit.html",
      changeset: Aircraft.admin_changeset(conn.assigns.aircraft, %{}),
      skip_shool_select: true,
      redirect_to: params["redirect_to"]
    )
  end

  def update(conn, %{"data" => aircraft_data}) do
    redirect_to = get_redirect_param(aircraft_data)

    case Scheduling.admin_update_aircraft(conn.assigns.aircraft, aircraft_data) do
      {:ok, aircraft} ->
        conn
        |> put_flash(:success, "Successfully updated aircraft.")
        |> redirect(to: redirect_to || "/admin/aircrafts/#{aircraft.id}")

      {:error, changeset} ->
        conn
        |> render("edit.html", changeset: changeset, redirect_to: redirect_to)
    end
  end

  def delete(conn, params) do
    Scheduling.archive_aircraft(conn.assigns.aircraft)

    conn
    |> put_flash(:success, "Aircraft successfully archived.")
    |> redirect(to: params["redirect_to"] || "/admin/aircrafts")
  end

  defp get_aircraft(conn, _) do
    aircraft = Scheduling.get_aircraft(conn.params["id"] || conn.params["aircraft_id"], conn)

    cond do
      aircraft && !aircraft.archived ->
        assign(conn, :aircraft, aircraft)

      aircraft && aircraft.archived ->
        conn
        |> put_flash(:error, "Aircraft already removed.")
        |> redirect(to: "/admin/aircrafts")
        |> halt()

      true ->
        conn
        |> put_flash(:error, "Unknown aircraft.")
        |> redirect(to: "/admin/aircrafts")
        |> halt()
    end
  end

  defp set_message(search_param) do
    if String.trim(search_param) == "" do
      "Please fill out search field"
    end
  end
end

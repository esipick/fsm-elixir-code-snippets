defmodule FlightWeb.Admin.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling
  alias Flight.Scheduling.Aircraft
  alias Flight.Repo
  alias Flight.Accounts
  alias Fsm.Inspections
  alias Fsm.Aircrafts.InspectionData
  alias Fsm.Aircrafts.ExpiredInspection

  import FlightWeb.Admin.AssetsHelper

  plug(:get_aircraft when action in [:logs, :show, :view, :edit, :update, :delete])

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
    aircraft = conn.assigns.aircraft
    user = conn.assigns.current_user

    inspections =
      Inspections.get_inspections(aircraft.id)
      |> Enum.map(fn inspection ->
        inspection_data =
          Enum.reduce(inspection.inspection_data, %{}, fn item, agg ->
            value = InspectionData.value_from_t_field(item)

            case item.class_name do
              "last_inspection" ->
                Map.put(agg, :last_inspection, value)

              "next_inspection" ->
                Map.put(agg, :next_inspection, value)
            end
          end)

        inspection = Map.merge(inspection, inspection_data)
        inspection = Map.put(inspection, :aircraft, aircraft)
        # For due inspection column
        expiration = ExpiredInspection.inspection_description(inspection)
        last_inspection = ExpiredInspection.last_inspection_description(inspection)
        next_inspection = ExpiredInspection.next_inspection_description(inspection)
        inspection_status = ExpiredInspection.inspection_status(inspection)
        icon_url = case inspection_status do
          :expired->
            "https://production-flight-boss.s3.amazonaws.com/pastDue.png"
          :good->
            "https://production-flight-boss.s3.amazonaws.com/plane.png"
          :expiring->
            "https://production-flight-boss.s3.amazonaws.com/attention.png"
        end
        inspection = inspection
                     |> Map.put(:last_inspection, last_inspection)
                     |> Map.put(:next_inspection, next_inspection)
                     |> Map.put(:inspection_status, inspection_status)
                     |> Map.put(:expiration, expiration)
                     |> Map.put(:icon_url, icon_url)
      end)

    squawks = Fsm.Squawks.get_squawks({aircraft.id, user.id})

    conn
    |> render("show.html", aircraft: aircraft, squawks: squawks, inspections: inspections, skip_shool_select: true)
  end

  def view(conn, _params) do
    aircraft = conn.assigns.aircraft
    user = conn.assigns.current_user
    squawks = Fsm.Squawks.get_squawks({aircraft.id, user.id})

    conn
    |> render("view.html", aircraft: aircraft, squawks: squawks, skip_shool_select: true)
  end

  def logs(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftLogsListData.build(conn, page_params, search_term)
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

  defp get_aircraft(%{assigns: %{current_user: current_user}} = conn, _) do
    aircraft = Scheduling.get_aircraft(conn.params["id"] || conn.params["aircraft_id"], conn)

    cond do
      aircraft && !aircraft.archived ->
        assign(conn, :aircraft, aircraft)

      aircraft && aircraft.archived ->
        conn
        |> put_flash(:error, "Aircraft already removed.")
        |> redirect(to: "/admin/aircrafts")
        |> halt()
      Accounts.has_role?(current_user, "instructor") || Accounts.has_role?(current_user, "student") ->
        conn
        |> put_flash(:error, "Unknown aircraft.")
        |> redirect(to: "/aircrafts/list")
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

  def list(conn, params) do
    search_term = Map.get(params, "search", "")
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftListData.build(conn, page_params, search_term)
    message = params["search"] && set_message(params["search"])

    conn
    |> render("list.html", data: data, message: message, tab: :aircraft)
  end
end

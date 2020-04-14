defmodule FlightWeb.Admin.InspectionController do
  use FlightWeb, :controller

  plug(:get_aircraft when action in [:create, :new])
  plug(:get_inspection when action in [:edit, :update, :delete])

  alias Flight.Scheduling
  alias Flight.Scheduling.{DateInspection, TachInspection, Inspection}

  def create(conn, %{"date_inspection" => date_inspection_data}) do
    data = Map.put(date_inspection_data, "aircraft_id", conn.assigns.aircraft.id)

    case Scheduling.create_date_inspection(data) do
      {:ok, _inspection} ->
        conn
        |> put_flash(:success, "Successfully created inspection")
        |> redirect(to: "/admin/aircrafts/#{conn.assigns.aircraft.id}")

      {:error, changeset} ->
        render(
          conn,
          "new.html",
          aircraft: conn.assigns.aircraft,
          changeset: changeset,
          form_type: :date
        )
    end
  end

  def create(conn, %{"tach_inspection" => tach_inspection_data}) do
    data = Map.put(tach_inspection_data, "aircraft_id", conn.assigns.aircraft.id)

    case Scheduling.create_tach_inspection(data) do
      {:ok, _inspection} ->
        conn
        |> put_flash(:success, "Successfully created inspection")
        |> redirect(to: "/admin/aircrafts/#{conn.assigns.aircraft.id}")

      {:error, changeset} ->
        render(
          conn,
          "new.html",
          aircraft: conn.assigns.aircraft,
          changeset: changeset,
          form_type: :tach
        )
    end
  end

  def new(conn, %{"type" => type}) do
    {form_type, changeset} =
      case type do
        "date" -> {:date, Scheduling.DateInspection.new_changeset()}
        "tach" -> {:tach, Scheduling.TachInspection.new_changeset()}
      end

    render(
      conn,
      "new.html",
      aircraft: conn.assigns.aircraft,
      changeset: changeset,
      form_type: form_type,
      skip_shool_select: true
    )
  end

  def new(conn, _params) do
    redirect(conn, to: "/admin/aircrafts/#{conn.assigns.aircraft.id}/inspections/new?type=date")
  end

  def edit(conn, _params) do
    {changeset, form_type} =
      case conn.assigns.inspection.type do
        "date" ->
          {DateInspection.changeset(Inspection.to_specific(conn.assigns.inspection), %{}), :date}

        "tach" ->
          {TachInspection.changeset(Inspection.to_specific(conn.assigns.inspection), %{}), :tach}
      end

    render(
      conn,
      "edit.html",
      inspection: conn.assigns.inspection,
      changeset: changeset,
      form_type: form_type,
      skip_shool_select: true
    )
  end

  def update(conn, %{"inspection" => inspection_data}) do
    case Scheduling.update_inspection(conn.assigns.inspection, inspection_data) do
      {:ok, _inspection} ->
        conn
        |> put_flash(:success, "Successfully created inspection")
        |> redirect(to: "/admin/aircrafts/#{conn.assigns.inspection.aircraft.id}")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          inspection: conn.assigns.inspection,
          changeset: changeset,
          form_type: String.to_atom(conn.assigns.inspection.type)
        )
    end
  end

  def delete(conn, _) do
    Scheduling.delete_inspection!(conn.assigns.inspection)

    conn
    |> put_flash(:success, "Inspection deleted")
    |> redirect(to: "/admin/aircrafts/#{conn.assigns.inspection.aircraft.id}")
  end

  defp get_aircraft(conn, _) do
    aircraft = Scheduling.get_aircraft(conn.params["aircraft_id"], conn)

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

  defp get_inspection(conn, _) do
    inspection = Scheduling.get_inspection(conn.params["id"])

    if inspection do
      cond do
        Scheduling.get_visible_aircraft(inspection.aircraft_id, conn) ->
          inspection = Flight.Repo.preload(inspection, :aircraft)
          assign(conn, :inspection, inspection)

        true ->
          conn
          |> put_flash(:error, "Aircraft already removed.")
          |> redirect(to: "/admin/aircrafts")
          |> halt()
      end
    else
      conn
      |> put_flash(:error, "Inspection not exists or already removed.")
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end
end

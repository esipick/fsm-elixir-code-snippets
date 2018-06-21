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

  def create(conn, %{"tach_inspection" => date_inspection_data}) do
    data = Map.put(date_inspection_data, "aircraft_id", conn.assigns.aircraft.id)

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
    form_type =
      case type do
        "date" -> :date
        "tach" -> :tach
      end

    render(
      conn,
      "new.html",
      aircraft: conn.assigns.aircraft,
      changeset: Scheduling.DateInspection.new_changeset(),
      form_type: form_type
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
      form_type: form_type
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
    aircraft = Scheduling.get_aircraft(conn.params["aircraft_id"])

    if aircraft do
      assign(conn, :aircraft, aircraft)
    else
      conn
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end

  defp get_inspection(conn, _) do
    inspection = Scheduling.get_inspection(conn.params["id"])

    if inspection do
      inspection = Flight.Repo.preload(inspection, :aircraft)
      assign(conn, :inspection, inspection)
    else
      conn
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end
end
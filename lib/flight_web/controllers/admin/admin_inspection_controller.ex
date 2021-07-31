defmodule FlightWeb.Admin.InspectionController do
  use FlightWeb, :controller

  plug(:get_aircraft when action in [:create, :new])
  plug(:get_inspection when action in [:edit, :update, :delete])

  alias Flight.Scheduling
  alias Flight.Scheduling.{Aircraft, DateInspection, TachInspection}
  alias Flight.Repo
  alias Fsm.Aircrafts.Inspection
  alias Fsm.Inspections

  def create(conn, %{"date_inspection" => date_inspection_data}) do

    user = conn.assigns.current_user

    last_inspection_data = %{
      type: :date,
      name: Map.get(date_inspection_data, "name"),
      class_name: "last_inspection",
      t_date: :date,
      value: Map.get(date_inspection_data, "last_inspection")
    }

    next_inspection_data = %{
      type: :date,
      name: Map.get(date_inspection_data, "name"),
      class_name: "next_inspection",
      t_date: :date,
      value: Map.get(date_inspection_data, "next_inspection")
    }

    inspection = %{
      type: Map.get(date_inspection_data, "type"),
      name: Map.get(date_inspection_data, "name"),
      aircraft_id: conn.assigns.aircraft.id,
      date_tach: :date,
      inspection_data: [
        last_inspection_data,
        next_inspection_data,
      ]
    }

    case Inspections.add_inspection(inspection, user) do
      {:ok, inspection} ->
          redirect_to_asset(conn, inspection)

      {:error, changeset} ->
        render(
          conn,
          "new.html",
          asset_namespace: asset_namespace(conn.assigns.aircraft),
          aircraft: conn.assigns.aircraft,
          changeset: changeset,
          form_type: :date
        )
    end
  end

  def create(conn, %{"tach_inspection" => tach_inspection_data}) do
    user = conn.assigns.current_user


    last_inspection_type  = Map.get(tach_inspection_data, "last_inspection") |> get_inspection_value_type()
    next_inspection_type  = Map.get(tach_inspection_data, "next_inspection") |> get_inspection_value_type()

    last_inspection_data = %{
      type: last_inspection_type,
      name: Map.get(tach_inspection_data, "name"),
      class_name: "last_inspection",
      value: Map.get(tach_inspection_data, "last_inspection")
    }

    next_inspection_data = %{
      type: next_inspection_type,
      name: Map.get(tach_inspection_data, "name"),
      class_name: "next_inspection",
      value: Map.get(tach_inspection_data, "next_inspection")
    }


    inspection = %{
      type: Map.get(tach_inspection_data, "type"),
      name: Map.get(tach_inspection_data, "name"),
      aircraft_id: conn.assigns.aircraft.id,
      date_tach: :tach,
      inspection_data: [
        get_merged_inspection_data(last_inspection_type, last_inspection_data),
        get_merged_inspection_data(next_inspection_type, next_inspection_data),
      ]
    }

    case Inspections.add_inspection(inspection, user) do
      {:ok, inspection} ->
        redirect_to_asset(conn, inspection)

      {:error, changeset} ->
        render(
          conn,
          "new.html",
          asset_namespace: asset_namespace(conn.assigns.aircraft),
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

    changeset = Inspection.new_changeset()

    render(
      conn,
      "new.html",
      asset_namespace: asset_namespace(conn.assigns.aircraft),
      aircraft: conn.assigns.aircraft,
      changeset: changeset,
      form_type: form_type,
      skip_shool_select: true
    )
  end

  def new(conn, _params) do
    aircraft = conn.assigns.aircraft
    namespace = asset_namespace(aircraft)

    redirect(conn, to: "/admin/#{namespace}/#{aircraft.id}/inspections/new?type=date")
  end

  def edit(conn, _params) do
    {changeset, form_type} =
      case conn.assigns.inspection.type do
        "date" ->
          {Inspection.changeset(Inspection.to_specific(conn.assigns.inspection), %{}), :date}

        "tach" ->
          {Inspection.changeset(Inspection.to_specific(conn.assigns.inspection), %{}), :tach}
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

    user = conn.assigns.current_user

    case Scheduling.update_inspection(conn.assigns.inspection, inspection_data) do
      {:ok, inspection} ->
        aircraft = Repo.preload(inspection, :aircraft).aircraft
        namespace = asset_namespace(aircraft)

        conn
        |> put_flash(:success, "Successfully created inspection")
        |> redirect(to: "/admin/#{namespace}/#{aircraft.id}")

      {:error, changeset} ->
        render(
          conn,
          "edit.html",
          inspection: conn.assigns.inspection,
          changeset: changeset,
          form_type: String.to_atom(conn.assigns.inspection.date_tach)
        )
    end
  end

  def delete(conn, _) do
    inspection = conn.assigns.inspection
    Scheduling.delete_inspection!(inspection)

    aircraft = conn.assigns.inspection.aircraft
    namespace = asset_namespace(aircraft)

    conn
    |> put_flash(:success, "Inspection deleted")
    |> redirect(to: "/admin/#{namespace}/#{aircraft.id}")
  end

  defp get_aircraft(conn, _) do
    vehicle_id = conn.params["aircraft_id"] || conn.params["simulator_id"]
    aircraft = Scheduling.get_aircraft(vehicle_id, conn)

    cond do
      aircraft && !aircraft.archived ->
        assign(conn, :aircraft, aircraft)

      aircraft && aircraft.archived ->
        redirect_from_deleted_asset_page(aircraft)

      true ->
        conn
        |> put_flash(:error, "Unknown asset.")
        |> redirect(to: "/admin/aircrafts")
        |> halt()
    end
  end

  defp get_inspection(conn, _) do
    inspection = Scheduling.get_inspection(conn.params["id"])

    if inspection do
      aircraft = Scheduling.get_visible_air_asset(inspection.aircraft_id, conn)

      cond do
        aircraft && !aircraft.archived ->
          inspection = Repo.preload(inspection, :aircraft)
          assign(conn, :inspection, inspection)

        aircraft && aircraft.archived ->
          redirect_from_deleted_asset_page(conn, aircraft)

        true ->
          redirect_from_deleted_asset_page(conn)
      end
    else
      conn
      |> put_flash(:error, "Inspection not exists or already removed.")
      |> redirect(to: "/admin/aircrafts")
      |> halt()
    end
  end

  defp redirect_from_deleted_asset_page(conn, aircraft \\ nil) do
    conn
    |> put_flash(:error, "#{Aircraft.display_name(aircraft)} already removed.")
    |> redirect(to: "/admin/#{asset_namespace(aircraft)}")
    |> halt()
  end

  defp redirect_to_asset(conn, inspection) do
    aircraft = Repo.preload(inspection, :aircraft).aircraft
    namespace = asset_namespace(aircraft)

    conn
    |> put_flash(:success, "Successfully created inspection")
    |> redirect(to: "/admin/#{namespace}/#{aircraft.id}")
  end

  defp asset_namespace(aircraft) do
    (Aircraft.display_name(aircraft) |> String.downcase()) <> "s"
  end

  defp get_inspection_value_type (val) do
    if(val === nil or val === "") do
      :string
    else
      case Integer.parse(val) do
        {:error}  ->
          :string
        {int_val, int_rest} ->
          case int_rest === "" do
            true -> :integer
            false ->
              case Float.parse(val) do
                {:error}  ->
                  :string
                {float_val, float_rest} ->
                  if float_rest === "", do: :float, else: :string
              end
          end
      end
    end
  end

  defp  get_merged_inspection_data(type, inspection_data) do
    case type do
      :float ->
        Map.put(inspection_data, :t_float, type)
      :integer ->
        Map.put(inspection_data, :t_int, type)
      :string ->
        Map.put(inspection_data, :t_str, type)
      _ ->
        Map.put(inspection_data, :t_str, :string)
    end
  end

end

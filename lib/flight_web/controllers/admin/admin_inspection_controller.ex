defmodule FlightWeb.Admin.InspectionController do
  use FlightWeb, :controller

  plug(:allow_only_admin when action in [:new, :create, :edit, :update, :delete])
  plug(:get_aircraft when action in [:create, :new])
  plug(:get_inspection when action in [:edit, :update, :delete])

  alias Flight.Scheduling
  alias Flight.Scheduling.{Aircraft}
  alias Flight.Repo
  alias Fsm.Aircrafts.Inspection
  alias Fsm.Inspections
  alias Flight.Accounts.Role
  alias Flight.Auth.Authorization

  def create(conn, %{"date_inspection" => date_inspection_data}) do

    user = conn.assigns.current_user

    last_date = Map.get(date_inspection_data, "last_inspection")
    next_date = Map.get(date_inspection_data, "next_inspection")

    last_inspection_data = %{
      type: :date,
      name: "Last inspection date",
      class_name: "last_inspection",
      value: last_date
    }

    next_inspection_data = %{
      type: :date,
      name: "Next inspection date",
      class_name: "next_inspection",
      value: next_date
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

    {:ok, last_date} = Date.from_iso8601(last_date)
    {:ok, next_date} = Date.from_iso8601(next_date)

    message = validate_date_value(last_date, next_date)

    if message != nil do
      render_inspection_error(conn, date_inspection_data, message, :date)
    else
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
  end

  def create(conn, %{"tach_inspection" => tach_inspection_data}) do
    user = conn.assigns.current_user

    last_value = Map.get(tach_inspection_data, "last_inspection")
    next_value = Map.get(tach_inspection_data, "next_inspection")

    # :int, :float and :string
    last_value_type  = get_inspection_value_type(last_value)
    next_value_type  = get_inspection_value_type(next_value)

    last_inspection_data = %{
      type: last_value_type,
      name: "Last Inspection Tach Time",
      class_name: "last_inspection",
      value: last_value
    }

    next_inspection_data = %{
      type: next_value_type,
      name: "Next Inspection Tach Time",
      class_name: "next_inspection",
      value: next_value
    }

    inspection = %{
      type: Map.get(tach_inspection_data, "type"),
      name: Map.get(tach_inspection_data, "name"),
      aircraft_id: conn.assigns.aircraft.id,
      date_tach: :tach,
      inspection_data: [
        get_merged_inspection_data(last_value_type, last_inspection_data),
        get_merged_inspection_data(next_value_type, next_inspection_data),
      ]
    }

    last_value = if last_value_type == :int or last_value_type == :float do
      {last_value, _} = if last_value_type == :int, do: Integer.parse(last_value), else: Float.parse(last_value)
      last_value
    end

   next_value = if next_value_type == :int or next_value_type == :float do
      {next_value, _} = if next_value_type == :int, do: Integer.parse(next_value), else: Float.parse(next_value)
      next_value
    end

    message = validate_tach_value(last_value, next_value, last_value_type, next_value_type)

    if message != nil do
      render_inspection_error(conn, tach_inspection_data, message, :tach)
    else
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

    form_type = conn.assigns.inspection.date_tach
    
    # using case here to make sure to handle
    # future requests for :tach and :date
    inspection_data = case form_type do
      :date ->
        conn.assigns.inspection.inspection_data
          |> Enum.reduce(%{}, fn(item, agg) ->
              if item.class_name === "last_inspection" do
                Map.put(agg, :last_inspection, Date.to_iso8601(item.t_date))
              else
                Map.put(agg, :next_inspection, Date.to_iso8601(item.t_date))
              end
          end)
      :tach ->
        conn.assigns.inspection.inspection_data
          |> Enum.reduce(%{}, fn(item, agg) ->

            value = case item.type do
              :int ->
                item.t_int
              :float ->
                item.t_float
              :string ->
                item.t_str
            end

            if item.class_name === "last_inspection" do
              Map.put(agg, :last_inspection, value)
            else
              Map.put(agg, :next_inspection, value)
            end
          end)
    end

    inspection = Map.merge(conn.assigns.inspection, inspection_data)

    changeset = Inspection.changeset(inspection, %{})

    render(
      conn,
      "edit.html",
      inspection: inspection,
      changeset: changeset,
      form_type: conn.assigns.inspection.date_tach,
      skip_shool_select: true
    )
  end

  def update(conn, %{"inspection" => inspection_data}) do

    user = conn.assigns.current_user
    inspection = conn.assigns.inspection

    last_value = Map.get(inspection_data, "last_inspection")
    next_value = Map.get(inspection_data, "next_inspection")

    inspection_data_list = case inspection.date_tach do
      :date ->
        [
          %{
            type: :date,
            name: Map.get(inspection_data, "name"),
            class_name: "last_inspection",
            value: last_value
          },
          %{
            type: :date,
            name: Map.get(inspection_data, "name"),
            class_name: "next_inspection",
            value: next_value
          }
        ]
      :tach ->
        [
          %{
            type: get_inspection_value_type(last_value),
            name: Map.get(inspection_data, "name"),
            class_name: "last_inspection",
            value: last_value
          },

          %{
            type: get_inspection_value_type(next_value),
            name: Map.get(inspection_data, "name"),
            class_name: "next_inspection",
            value: next_value
          }
        ]
    end

    message = if inspection.date_tach == :date do
      {:ok, last_value} = Date.from_iso8601(last_value)
      {:ok, next_value} = Date.from_iso8601(next_value)

      validate_date_value(last_value, next_value)
    else
      last_value_type  = get_inspection_value_type(last_value)
      next_value_type  = get_inspection_value_type(next_value)
      
      last_value = if last_value_type == :int or last_value_type == :float do
        {last_value, _} = if last_value_type == :int, do: Integer.parse(last_value), else: Float.parse(last_value)
        last_value
      end

      next_value = if next_value_type == :int or next_value_type == :float do
        {next_value, _} = if next_value_type == :int, do: Integer.parse(next_value), else: Float.parse(next_value)
        next_value
      end

      validate_tach_value(last_value, next_value, last_value_type, next_value_type)
    end

    if message != nil do
      render_edit_inspection_error(conn, inspection_data, message, inspection.date_tach)
    else
      case Inspections.update_inspection(inspection.id, inspection_data_list) do
        {:ok, inspection} ->
          aircraft = conn.assigns.inspection.aircraft
          namespace = asset_namespace(aircraft)

          conn
          |> put_flash(:success, "Successfully updated inspection")
          |> redirect(to: "/admin/#{namespace}/#{aircraft.id}")

        {:error, changeset} ->
          render(
            conn,
            "edit.html",
            inspection: conn.assigns.inspection,
            changeset: changeset,
            form_type: conn.assigns.inspection.date_tach
          )
      end
    end
  end

  def delete(conn, _) do
    inspection = conn.assigns.inspection
    Inspections.delete_inspection(inspection)

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
    inspection = Inspections.get_inspection_by_inspection_id(conn.params["id"])

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
    if(val == nil or val == "") do
      :string
    else
      case Integer.parse(val) do
        :error  ->
          :string
        {int_val, int_rest} ->
          case int_rest == "" do
            true -> :int
            false ->
              case Float.parse(val) do
                :error  ->
                  :string
                {float_val, float_rest} ->
                  if float_rest == "", do: :float, else: :string
              end
          end
      end
    end
  end

  defp  get_merged_inspection_data(type, inspection_data) do
    case type do
      :float ->
        Map.put(inspection_data, :t_float, type)
      :int ->
        Map.put(inspection_data, :t_int, type)
      :string ->
        Map.put(inspection_data, :t_str, type)
      _ ->
        Map.put(inspection_data, :t_str, :string)
    end
  end

  defp allow_only_admin(conn, _) do
    user = Repo.preload(conn.assigns.current_user, [:roles])
    roles = Role |> Flight.Repo.all()

    if Authorization.is_admin?(user) do
      conn
    else
      Authorization.Extensions.redirect_unathorized_user(conn)
    end
  end

  defp render_inspection_error(conn, inspection_data, error, type) do
    changeset = prepare_changeset(inspection_data)
    render(
          conn |> put_flash(:error, error),
          "new.html",
          asset_namespace: asset_namespace(conn.assigns.aircraft),
          aircraft: conn.assigns.aircraft,
          changeset: changeset,
          form_type: type
        )
  end

  defp render_edit_inspection_error(conn, inspection_data, error, type) do
    inspection = conn.assigns.inspection
    inspection_data = Map.put(inspection_data, "name", inspection.name)
    inspection_data = Map.put(inspection_data, "type", inspection.type)

    changeset = prepare_changeset(inspection_data)
    # have to check this, why we don't have aircraft in conn.assigns
    # for now, it works fine
    render(
          conn |> put_flash(:error, error),
          "edit.html",
          changeset: changeset,
          form_type: type
        )
  end

  defp prepare_changeset(inspection_data) do
    inspection_data = %{
      type: Map.get(inspection_data, "type"),
      name: Map.get(inspection_data, "name"),
      last_inspection: Map.get(inspection_data, "last_inspection"),
      next_inspection: Map.get(inspection_data, "next_inspection"),
    }

    changeset = Inspection.new_changeset()
    changeset = Map.put(changeset, :data, Map.merge(changeset.data, inspection_data))
  end

  defp validate_date_value(last, next) do
      cond do
        Date.compare(last, Date.utc_today) == :gt  ->
            "Last inspection date cannot be ahead of today"
        Date.compare(last, next) == :gt ->
            "Last inspection date cannot be ahead of next inspection date"
        Date.compare(next, Date.utc_today) == :lt ->
            "Next inspection date cannot be behind today"
        Date.compare(last, next) == :eq ->
            "Last inspection date connot be same as next inspection date"
        true ->
          nil
    end
  end

  defp validate_tach_value(last, next, last_type, next_type) do
    cond do
      last_type == :string or next_type == :string ->
        "Last or next inspection tach value should be a number"
      last > next or last == next ->
        "Next inspection tach value should be greater than last inspection tach value"
      true ->
        nil
    end
  end

end

defmodule FlightWeb.API.AircraftController do
  use FlightWeb, :controller

  alias Flight.Scheduling
  alias Flight.Auth.Permission
  alias Flight.Ecto.Errors

  plug(:authorize_view_all when action in [:autocomplete])
  plug(:authorize_create when action in [:create])

  def create(conn, %{"data" => aircraft_data}) when is_map(aircraft_data) do
    case Scheduling.admin_create_aircraft(aircraft_data, conn) do
      {:ok, _aircraft} ->
        json(conn, %{"result" => "success"})

      {:error, changeset} ->
          json(conn, %{human_errors: [Errors.traverse(changeset)]})
    end
  end

  def index(conn, _) do
    aircrafts =
      Scheduling.visible_air_assets(conn)
      |> Flight.Repo.preload(:inspections)

    render(conn, "index.json", aircrafts: aircrafts)
  end

  def simulators(conn, _) do
    simulators =
      Scheduling.visible_simulators(conn)
      |> Flight.Repo.preload(:inspections)

    render(conn, "index.json", aircrafts: simulators)
  end

  def show(conn, %{"id" => id}) do
    aircraft =
      Scheduling.get_visible_air_asset(id, conn)
      |> Flight.Repo.preload(:inspections)

    render(conn, "show.json", aircraft: aircraft)
  end

  def autocomplete(conn, %{"search" => search_term} = _params) do
    aircrafts =
      Scheduling.visible_air_assets_query(conn, search_term)
      |> Flight.Repo.all()

    render(conn, "autocomplete.json", aircrafts: aircrafts)
  end

  def update_status(conn, %{"id" => id, "block" => block}) do
    
    with {:ok, _aircraft} <- Scheduling.block_aircraft(id, block, conn) do
      json(conn, %{"result" => "success"})

    else
      {:error, changeset} ->
        error = Flight.Ecto.Errors.traverse(changeset) 
      json(conn, %{"human_errors" => [error]})
    end
  end

  def authorize_view_all(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:aircraft, :view, :all)])
  end

  def authorize_create(conn, _) do
    halt_unless_user_can?(conn, [Permission.new(:aircraft, :modify, :all)])
  end
end

defmodule Fsm.Aircrafts do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Fsm.Accounts.User
  alias Fsm.Aircrafts.AircraftsQueries
  alias Fsm.SchoolScope
  alias Fsm.Aircrafts.InspectionData

  require Logger

  def get_aircraft(id) do
      AircraftsQueries.get_aircraft_query(id)
      |> Repo.one
      |> Repo.preload(:squawks)
  end

  def get_aircraft_record_by_id(id) do
      AircraftsQueries.get_aircraft_record_by_id_query(id)
      |> Repo.one
  end

  def list_aircrafts(page, per_page, sort_field, sort_order, filter, context) do

    inspections_query = from p in Fsm.Aircrafts.Inspection

    AircraftsQueries.list_aircrafts_query(page, per_page, sort_field, sort_order, filter, context)
    |> Repo.all()
    |> Repo.preload([:squawks])
    |> Repo.preload([inspections: {inspections_query, [:inspection_data, :attachments]}])
    |> Enum.reduce([], fn(aircraft, agg) ->

      inspections = Enum.map(aircraft.inspections, fn(is) ->
        changed_data = Enum.map(is.inspection_data, fn(d) ->
            %{d | value: InspectionData.value_from_t_field(d)}
        end)
        %{is | inspection_data: changed_data}
      end)

      aircraft = Map.put(aircraft, :inspections, inspections)
      agg ++ [aircraft]
    end)

  end

  defp sort_by(query, nil, nil) do
    query
  end

  defp sort_by(query, sort_field, sort_order) do
    from g in query,
         order_by: [{^sort_order, field(g, ^sort_field)}]
  end

  def search(query, %{search_criteria: _, search_term: ""}) do
    query
  end

  def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
    case search_criteria do
      :first_name ->
        from s in query,
             where: ilike(s.name, ^"%#{search_term}%")

      :last_name ->
        from s in query,
             where: ilike(s.last_name, ^"%#{search_term}%")

      :email ->
        from s in query,
             where: ilike(s.email, ^"%#{search_term}%")

      _ ->
        query
    end
  end

  def search(query, _) do
    query
  end

  defp filter(query, nil) do
    query
  end

  defp filter(query, filter) do
    Logger.debug "filter: #{inspect filter}"
    Enum.reduce(filter, query, fn ({key, value}, query) ->
      case key do
        :id ->
          from g in query,
          where: g.id == ^ value

        :archived ->
          from g in query,
          where: g.archived == ^ value

        _ ->
        query
      end
    end)
  end

  def paginate(query, 0, 0) do
    query
  end

  def paginate(query, 0, size) do
    from query,
    limit: ^size
  end

  def paginate(query, page, size) do
    from query,
    limit: ^size,
    offset: ^((page-1) * size)
  end
end

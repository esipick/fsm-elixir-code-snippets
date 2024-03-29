defmodule FsmWeb.GraphQL.Aircrafts.AircraftsResolvers do
  alias Fsm.Aircrafts
  alias FsmWeb.GraphQL.Log
  def get_aircraft(parent, args, %{context: %{current_user: %{id: id}}}=context) do
    aircraft = Aircrafts.get_aircraft(args.id)
    resp = {:ok, aircraft}
    Log.response(resp, __ENV__.function)
  end
  def list_aircrafts(parent, args, %{context: %{current_user: %{school_id: school_id}}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    aircrafts =
      Aircrafts.list_aircrafts(page, per_page, sort_field, sort_order, filter, context)

    resp = {:ok, %{aircrafts: aircrafts, page: page}}
    Log.response(resp, __ENV__.function, :info)
  end
  def get_inspections(parent, _args, _context) do
    {:ok, parent |> Flight.Repo.preload(:inspections)}
  end
end

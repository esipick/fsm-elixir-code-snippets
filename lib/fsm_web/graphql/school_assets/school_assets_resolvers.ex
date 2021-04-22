defmodule FsmWeb.GraphQL.SchoolAssets.SchoolAssetsResolvers do

  alias Fsm.SchoolAssets
  alias FsmWeb.GraphQL.Log

  def list_rooms(parent, args, %{context: %{current_user: %{school_id: _school_id}}}=context) do
    page = Map.get(args, :page)
    per_page = Map.get(args, :per_page)

    sort_field = Map.get(args, :sort_field) || :inserted_at
    sort_order = Map.get(args, :sort_order) || :desc
    filter = Map.get(args, :filter) || %{}
    rooms = SchoolAssets.list_rooms(page, per_page, sort_field, sort_order, filter, context)

    resp = {:ok, rooms}
    Log.response(resp, __ENV__.function, :info)
  end
end
  
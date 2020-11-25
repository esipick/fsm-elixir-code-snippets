defmodule FsmWeb.GraphQL.SchoolAssets.SchoolAssetsResolvers do

  alias Fsm.SchoolAssets
  alias FsmWeb.GraphQL.Log

  def list_rooms(parent, _args, %{context: %{current_user: %{school_id: _school_id}}}=context) do
    rooms = SchoolAssets.list_rooms(context)

    resp = {:ok, rooms}
    Log.response(resp, __ENV__.function, :info)
  end
end
  
defmodule Fsm.SchoolAssets do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Fsm.SchoolAssets.SchoolAssetsQueries

  def list_rooms(page, per_page, sort_field, sort_order, filter, conn) do
    SchoolAssetsQueries.list_rooms_query(page, per_page, sort_field, sort_order, filter, conn)
    |> Repo.all
  end

  def get_room(id, context) do
    SchoolAssetsQueries.get_room(id, context)
    |> Repo.one()
  end
end
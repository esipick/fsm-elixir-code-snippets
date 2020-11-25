defmodule Fsm.SchoolAssets do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Fsm.SchoolAssets.SchoolAssetsQueries

  def list_rooms(conn) do
    SchoolAssetsQueries.list_rooms_query(conn)
    |> Repo.all
  end
end
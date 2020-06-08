defmodule Flight.SchoolAssets do
  alias Flight.SchoolAssets.Room

  alias Flight.Repo
  alias Flight.SchoolScope

  import Ecto.Query, warn: false

  def get_room(id, school_context) do
    room_query(school_context)
    |> where([r], r.id == ^id)
    |> Repo.one()
  end

  def visible_room_query(school_context) do
    room_query(school_context) |> where([r], r.archived == false)
  end

  def room_query(school_context) do
    Room
    |> order_by([r], asc: [r.location])
    |> SchoolScope.scope_query(school_context)
  end
end

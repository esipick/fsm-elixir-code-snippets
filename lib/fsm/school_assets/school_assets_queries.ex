defmodule Fsm.SchoolAssets.SchoolAssetsQueries do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Fsm.SchoolScope
  alias Fsm.SchoolAssets.Room

  def list_rooms_query(school_context) do
    Room
    |> SchoolScope.scope_query(school_context)
    |> order_by([c], desc: c.id)
  end
end

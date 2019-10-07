defmodule Flight.Queries.User do
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Accounts.{
    User,
    Search
  }

  alias Flight.SchoolScope

  def search_users_ids_by_name(search_term, school_context) do
    from(
      u in User,
      where: u.archived == false,
      order_by: u.last_name,
      select: %{id: u.id}
    )
    |> Search.User.name_only(search_term)
    |> Repo.all
    |> Enum.map(fn user -> user.id end)
  end
end

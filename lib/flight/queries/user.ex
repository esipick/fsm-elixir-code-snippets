defmodule Flight.Queries.User do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Flight.Accounts.{
    User,
    Search
  }

  def search_users_ids_by_name(search_term, _) do
    from(
      u in User,
      where: u.archived == false,
      order_by: u.last_name,
      select: %{id: u.id}
    )
    |> Search.User.name_only(search_term)
    |> Repo.all()
    |> Enum.map(fn user -> user.id end)
  end

  def search_users_by_name(search_term, role, school_context) do
    role
    |> Ecto.assoc(:users)
    |> Search.User.name_only(search_term)
    |> Flight.Accounts.default_users_query(school_context)
    |> Repo.all()
  end

  def get_users_by_role(role, school_context) do
    role
    |> Ecto.assoc(:users)
    |> Flight.Accounts.default_users_query(school_context)
    |> Repo.all()
  end
end

defmodule Flight.Queries.User do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Flight.Accounts.{
    User,
    Search,
    Role,
    UserRole
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

  def get_users_by_roles(roles, school_context) do
    from(u in User, select: u,
      inner_join: ur in UserRole, on: ur.user_id == u.id,
      inner_join: r in Role, on: r.id == ur.role_id and r.slug in ^roles, distinct: true)
    |> Flight.Accounts.default_users_query(school_context)
    |> Repo.all()
  end
end

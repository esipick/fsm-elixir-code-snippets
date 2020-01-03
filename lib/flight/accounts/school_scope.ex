defmodule Flight.SchoolScope do
  alias Flight.Accounts.{School}

  require Ecto.Query
  import Ecto.Query

  def scope_query(query, %{assigns: %{current_user: current_user}} = context) do
    case Flight.Accounts.is_superadmin?(current_user) do
      true -> query
      false -> school_scope(query, context)
    end
  end

  def scope_query(query, context) do
    school_scope(query, context)
  end

  def superadmin_query(query, %{assigns: %{current_user: current_user}} = context) do
    case Flight.Accounts.is_superadmin?(current_user) do
      true -> query |> preload(:school)
      false -> scope_query(query, context)
    end
  end

  def school_scope(query, context) do
    query |> where([s], s.school_id == ^school_id(context))
  end

  def school_changeset(struct, school_context) do
    %{struct | school_id: school_id(school_context)}
    |> Ecto.Changeset.cast(%{}, [:school_id])
    |> Ecto.Changeset.validate_required([:school_id])
  end

  def get_school(%School{} = school) do
    school
  end

  def get_school(school_context) do
    Flight.Repo.get(School, school_id(school_context))
  end

  def school_id(%Plug.Conn{assigns: %{current_user: user}}) do
    school_id(user)
  end

  def school_id(%School{id: id}) when is_integer(id) do
    id
  end

  def school_id(%{school_id: id}) when is_integer(id) do
    id
  end
end

defmodule Fsm.SchoolScope do
  alias Flight.Accounts.{School}

  require Ecto.Query
  import Ecto.Query

  def scope_query(query, %{context: %{current_user: %{school_id: school_id}=current_user}} = context) do
    school_context =
      case Flight.Accounts.is_superadmin?(current_user) do
        true -> school_id
        false -> context
      end

    school_scope(query, school_context)
  end

  def scope_query(query, %{context: %{current_user: current_user}} = context) do
    query
    |> preload_school(current_user)
    |> school_scope(context)
  end

  def school_scope(query, context) do
    query
    |> where([s], s.school_id == ^school_id(context))
  end

  def preload_school(query, user) do
    case Flight.Accounts.is_superadmin?(user) do
      true -> preload(query, :school)
      false -> query
    end
  end

  def school_changeset(struct, school_context) do
    %{struct | school_id: school_id(school_context)}
    |> Ecto.Changeset.cast(%{}, [:school_id])
    |> Ecto.Changeset.validate_required([:school_id])
  end
 def get_school(%School{} = school), do: school

 def get_school(school_context) do
   Flight.Repo.get(School, school_id(school_context))
 end

  def school_id(%{context: %{current_user: %{school_id: school_id}=current_user}}) do
    case Flight.Accounts.is_superadmin?(current_user) do
      true -> school_id
      false -> current_user
    end
    |> school_id
  end

  def school_id(%School{id: id}) when is_integer(id), do: id

  def school_id(%{school_id: id}) when is_integer(id), do: id

  def school_id(id) when is_integer(id), do: id
  def school_id(id), do: String.to_integer(id)
end

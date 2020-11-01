defmodule Fsm.Accounts do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Fsm.Accounts.User
  alias Fsm.Accounts.AccountsQueries
  alias Fsm.SchoolScope

  require Logger

  def api_login(%{"email" => email, "password" => password}) do

    case user = get_user_by_email(email) do
      %User{archived: true} ->
        {:error, %{human_errors: [FlightWeb.AuthenticateApiUser.account_suspended_error()]}}

      %User{archived: false} ->
        case check_password(user, password) do
          {:ok, user} ->
            user =
              user
              |> FlightWeb.API.UserView.show_preload()

            {:ok, %{user: user, token: FlightWeb.Fsm.AuthenticateApiUser.token(user)}}

          {:error, _} ->
            {:error, "Invalid email or password."}
        end

      _ ->
        Comeonin.Bcrypt.dummy_checkpw()

        {:error, "Invalid email or password."}
    end
  end

  def get_user(id) do
    user =
      AccountsQueries.get_user_with_roles(id)
      |> Repo.one
  end

  def list_users(page, per_page, sort_field, sort_order, filter, context) do
    from(u in User)
    |> sort_by(sort_field, sort_order)
    |> sort_by(:first_name, sort_order)
    |> filter(filter)
    |> search(filter)
    |> paginate(page, per_page)
    |> SchoolScope.scope_query(context)
    |> Repo.all()
  end

  defp get_user_by_email(email) when is_nil(email) or email == "", do: nil

  defp get_user_by_email(email) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> Repo.one()
  end

  defp check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end

  defp sort_by(query, nil, nil) do
    query
  end

  defp sort_by(query, sort_field, sort_order) do
    from g in query,
         order_by: [{^sort_order, field(g, ^sort_field)}]
  end

  def search(query, %{search_criteria: _, search_term: ""}) do
    query
  end

  def search(query, %{search_criteria: search_criteria, search_term: search_term}) do
    case search_criteria do
      :first_name ->
        from s in query,
             where: ilike(s.name, ^"%#{search_term}%")

      :last_name ->
        from s in query,
             where: ilike(s.last_name, ^"%#{search_term}%")

      :email ->
        from s in query,
             where: ilike(s.email, ^"%#{search_term}%")

      _ ->
        query
    end
  end

  def search(query, _) do
    query
  end

  defp filter(query, nil) do
    query
  end

  defp filter(query, filter) do
    Logger.debug "filter: #{inspect filter}"
    Enum.reduce(filter, query, fn ({key, value}, query) ->
      case key do
        :id ->
          from g in query,
          where: g.id == ^ value

        :archived ->
          from g in query,
          where: g.archived == ^ value

        _ ->
        query
      end
    end)
  end

  def paginate(query, 0, 0) do
    query
  end

  def paginate(query, 0, size) do
    from query,
    limit: ^size
  end

  def paginate(query, page, size) do
    from query,
    limit: ^size,
    offset: ^((page-1) * size)
  end
end

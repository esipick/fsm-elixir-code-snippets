defmodule Fsm.Accounts do
  import Ecto.Query, warn: false

  alias Flight.Repo

  alias Fsm.Accounts.User
  alias Flight.Accounts.Role
  alias Flight.Accounts.UserRole
  alias Fsm.Accounts.AccountsQueries
  alias Fsm.SchoolScope
  alias Fsm.Email

  require Logger

  def user_changeset(user, attrs, school_context) do
    user
    |> SchoolScope.school_changeset(school_context)
    |> User.create_changeset(attrs)
  end

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

  def get_role(role_id, :id) do
    Repo.get(Role, role_id)
  end

  def get_role(role_slug, :slug) do
    AccountsQueries.get_role_by_slug_query(role_slug)
    |> Repo.one
  end

  def get_user(id) do
    user =
      AccountsQueries.get_user_query(id)
      |> Repo.one
  end

  def get_user_with_roles(id) do
    user =
      AccountsQueries.get_user_with_roles_query(id)
      |> Repo.one
  end

  def get_user_count(role, school_context) do
    from(
      u in User,
      where: u.archived == false,
      inner_join: r in assoc(u, :roles),
      where: r.id == ^role.id
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def roles_visible_to("student") do
    []
  end

  def roles_visible_to("instructor") do
    ["student"]
  end

  def roles_visible_to("renter") do
    []
  end

  def roles_visible_to("admin") do
    ["admin", "student", "renter", "instructor", "dispatcher"]
  end

  def roles_visible_to("dispatcher") do
    ["student", "renter", "instructor", "dispatcher"]
  end

  defp get_visible_roles(roles_visible, nil) do
    roles_visible
  end

  defp get_visible_roles(roles_visible, roles_filter) do
    roles_visible -- roles_visible -- roles_filter
  end

  def list_users(page, per_page, sort_field, sort_order, filter, %{context: %{current_user: %{id: user_id, school_id: school_id, roles: roles}}} = context) do

    user = get_user_with_roles(user_id)

    roles_filter = Map.get(filter, :roles)
    roles_visible = Enum.fetch!(roles, 0) 
                    |> roles_visible_to

    allowed_roles = get_visible_roles(roles_visible, roles_filter)
    users = AccountsQueries.list_users_query(page, per_page, sort_field, sort_order, filter, context, allowed_roles)
    |> Repo.all()

    if Enum.find(users, &(&1.user.id == user.id)) do
      users
    else
      [user | users]
    end
  end

  def list_instructors(page, per_page, sort_field, sort_order, filter, context) do
    AccountsQueries.list_instructors_query(page, per_page, sort_field, sort_order, filter, context)
    |> Repo.all()
  end

  def send_invitation_email(invitation) do
    Fsm.Email.invitation_email(invitation)
    |> Flight.Mailer.deliver_later()
  end

  def get_user_by_email(email) when is_nil(email) or email == "", do: nil

  def get_user_by_email(email) do
      AccountsQueries.get_user_by_email_query(email)
      |> Repo.one()
      |> case do
          nil -> 
            nil
          user ->
            (Map.get(user, :user) || %{})
            |> Map.merge(%{roles: Map.get(user, :roles)})
        end
  end

  def admin_update_user_profile(
        %User{} = user,
        attrs,
        role_slugs
#        ,aircrafts,
#        flyer_certificate_slugs,
#        instructors
      ) do
    update_user_profile(
      user,
      attrs,
      role_slugs, nil, nil, nil
#  ,
#      aircrafts,
#      flyer_certificate_slugs,
#      instructors,
#      &User.admin_update_changeset/3
    )
  end
  
  defp update_user_profile(
         user,
         attrs,
         role_slugs, nil, nil, nil
#           ,
#         aircraft_ids,
#         flyer_certificate_slugs,
#         instructor_ids,
#         changeset_func
       ) do
#    user =
#      Repo.preload(user, [:roles, :aircrafts, :flyer_certificates, :instructors, :main_instructor])
#
#    instructor_ids = instructor_ids || []
#    instructor_ids =
#      if user.main_instructor_id != nil do
#        [user.main_instructor_id | instructor_ids]
#
#      else
#        instructor_ids
#      end
#      |> Enum.uniq
#
    {valid_roles?, roles} =
      if role_slugs do
        roles = Repo.all(from(r in Role, where: r.slug in ^role_slugs))
        valid_roles? = Enum.count(role_slugs) == Enum.count(roles)
        {valid_roles?, roles}
      else
        {true, nil}
      end
#
#    {valid_aircrafts?, aircrafts, invalid_aircraft_ids} =
#      case aircraft_ids do
#        nil ->
#          {true, nil, []}
#
#        [] ->
#          {true, [], []}
#
#        aircraft_ids ->
#          aircrafts =
#            Repo.all(from(r in Flight.Scheduling.Aircraft, where: r.id in ^aircraft_ids))
#
#          invalid_aircraft_ids =
#            Enum.filter(aircraft_ids, fn id ->
#              aircraft = Enum.find(aircrafts, fn aircraft -> aircraft.id == id end)
#              aircraft.archived
#            end)
#
#          valid_aircrafts? =
#            Enum.count(aircraft_ids) == Enum.count(aircrafts) and invalid_aircraft_ids == []
#
#          {valid_aircrafts?, aircrafts, invalid_aircraft_ids}
#      end
#
#    {valid_certs?, certs} =
#      if flyer_certificate_slugs do
#        certs = Repo.all(from(c in FlyerCertificate, where: c.slug in ^flyer_certificate_slugs))
#        valid_certs? = Enum.count(flyer_certificate_slugs) == Enum.count(certs)
#        {valid_certs?, certs}
#      else
#        {true, nil}
#      end
#
#    {valid_instructors?, instructors, invalid_instructor_ids} =
#      case instructor_ids do
#        nil ->
#          {true, nil, []}
#
#        [] ->
#          {true, [], []}
#
#        instructor_ids ->
#          instructors = Repo.all(from(r in User, where: r.id in ^instructor_ids))
#
#          invalid_instructor_ids =
#            Enum.filter(instructor_ids, fn id ->
#              instructor = Enum.find(instructors, fn instructor -> instructor.id == id end)
#              instructor.archived
#            end)
#
#          valid_instructors? =
#            Enum.count(instructor_ids) == Enum.count(instructors) and invalid_instructor_ids == []
#
#          {valid_instructors?, instructors, invalid_instructor_ids}
#      end
#
#    valid_main_instructor? =
#      case attrs["main_instructor_id"] do
#        id when id in ["", nil] ->
#          true
#
#        id ->
#          main_instructor = Repo.one(from(r in User, where: r.id == ^id))
#          !main_instructor.archived and id != user.id
#      end

    avatar = user.avatar

#    cond do
#      !valid_roles? ->
#        {:error,
#          Ecto.Changeset.add_error(
#            changeset_func.(user, attrs, [], [], [], []),
#            :roles,
#            "are not all known: #{Enum.join(role_slugs, ", ")}"
#          )}
#
#      !valid_aircrafts? ->
#        message =
#          case invalid_aircraft_ids do
#            [] ->
#              "are not all known: #{Enum.join(role_slugs, ", ")}"
#
#            invalid_aircraft_ids ->
#              "should be active: #{Enum.join(invalid_aircraft_ids, ", ")}"
#          end
#
#        {:error,
#          Ecto.Changeset.add_error(
#            changeset_func.(user, attrs, [], [], [], []),
#            :aircrafts,
#            message
#          )}
#
#      !valid_certs? ->
#        {:error,
#          Ecto.Changeset.add_error(
#            changeset_func.(user, attrs, [], [], [], []),
#            :flyer_certificates,
#            "are not all known: #{Enum.join(flyer_certificate_slugs, ", ")}"
#          )}
#
#      !valid_instructors? ->
#        message =
#          case invalid_instructor_ids do
#            [] ->
#              "are not all known: #{Enum.join(role_slugs, ", ")}"
#
#            invalid_instructor_ids ->
#              "should be active: #{Enum.join(invalid_instructor_ids, ", ")}"
#          end
#
#        {:error,
#          Ecto.Changeset.add_error(
#            changeset_func.(user, attrs, [], [], [], []),
#            :instructors,
#            message
#          )}
#
#      !valid_main_instructor? ->
#        {:error,
#          Ecto.Changeset.add_error(
#            changeset_func.(user, attrs, [], [], [], []),
#            :main_instructor_id,
#            "should be active"
#          )}

#      true ->
        result =
          user
          |> User.admin_update_changeset(attrs
#            , roles, aircrafts, certs, instructors
                            )
          |> Repo.update()

    case result do
          {:ok, updated_user} ->
            if role_slugs not in [nil, "", []] do
              with {_count, nil} <- from(ui in UserRole, where: ui.user_id == ^user.id)
                                    |> Repo.delete_all(),
                    role_ids <- AccountsQueries.get_all_user_role_ids_query(user.id, role_slugs)
                                |> Repo.all(),
              user_role_ids <- Enum.map(role_ids, fn x -> Map.put(x, :user_id, user.id) end),
                   {_, _} = Repo.insert_all(UserRole, user_role_ids)
                  do
                updated_user
              end

            else
              updated_user
            end

#            if attrs["delete_avatar"] == "1" and avatar do
#              Flight.AvatarUploader.delete({avatar, updated_user})
#            end
#
#            instructor_exists = user.main_instructor_id != nil
#            is_main_instructor_updated? = updated_user.main_instructor_id != user.main_instructor_id
#
#            if is_main_instructor_updated? && instructor_exists do
#              delete_user_instructor(user.id, user.main_instructor_id)
#            end
#
#            if is_main_instructor_updated? do
#              insert_user_instructor(user.id, updated_user.main_instructor_id)
#            end
#


          error ->
            error
        end
#    end
  end

#  def update_user(id, params) do
#    user =
#      Repo.get(User, id)
#      |> case do
#           nil -> {:error, :user_not_found}
#           user ->
#             changeset = Fsm.Accounts.User.changeset(user, params)
#
#             changeset
#             |> Repo.update()
##             |> case do
##                  {:ok, new_user} ->
##
##                    new_user = %{
##                      id: new_user.id,
##                      title: new_user.title,
##                      file: %{
##                        name: user.file.file_name,
##                        url: get_file_url(user)
##                      }
##                    }
##                    {:ok, new_user}
##
##                  result ->
##                    result
##                end
#         end
#  end

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

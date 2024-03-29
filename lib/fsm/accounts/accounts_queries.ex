defmodule Fsm.Accounts.AccountsQueries do
    @moduledoc false

    import Ecto.Query, warn: false

    alias Fsm.Accounts.User
    alias Fsm.Accounts.UserRole
    alias Fsm.Accounts.Role
    alias Fsm.SchoolScope
    alias Flight.Accounts.UserInstructor

    require Logger

    def get_user_query(user_id) do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        select: %{user: u,
        roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
        group_by: u.id,
        where: u.id == ^user_id
    end

    def get_all_user_role_ids_query(user_id, role_slugs) do
      from ur in Role,
        select: %{role_id: ur.id},
        where: ur.slug in ^role_slugs
    end

    def get_all_school_role_slug_user_ids_query(school_id, role_slugs) do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        select: u.id,
        where: r.slug in ^role_slugs and u.school_id == ^school_id
    end

    def get_role_by_slug_query(slug) do
      from ur in Role,
        select: %{id: ur.id, slug: ur.slug},
        where: ur.slug == ^slug
    end

    def get_user_by_email_query(email) do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        select: %{user: u,
          roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
        group_by: u.id,
        where: u.email == ^String.downcase(email)
    end

    def get_all_users_query() do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        select: %{user: u,
          roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
        group_by: u.id
    end

    def get_all_users_query(roles) do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        where: r.slug in ^roles,
        select: %{user: u,
#        order_by: r.slug,
          roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
        group_by: u.id
    end

    def get_all_instructors_query do
      from u in User,
        inner_join: ur in UserRole, on: ur.user_id == u.id,
        inner_join: r in Role, on: r.id == ur.role_id,
        where: r.slug == ^"instructor",
        select: %{user: u,
          roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
        group_by: u.id
    end

    def get_user_with_roles_query(user_id) do
        from u in User,
            inner_join: ur in UserRole, on: ur.user_id == u.id,
            inner_join: r in Role, on: r.id == ur.role_id,
            select: %{id: u.id, email: u.email,
            date_of_birth: u.date_of_birth,
            gender: u.gender,
            emergency_contact_no: u.emergency_contact_no,
            d_license_no: u.d_license_no,
            d_license_expires_at: u.d_license_expires_at,
            d_license_state: u.d_license_state,
            passport_no: u.passport_no,
            passport_expires_at: u.passport_expires_at,
            passport_country: u.passport_country,
            passport_issuer_name: u.passport_issuer_name,
            last_faa_flight_review_at: u.last_faa_flight_review_at,
            renter_policy_no: u.renter_policy_no  ,
            first_name: u.first_name,
            last_name: u.last_name,
            archived: u.archived,
            school_id: u.school_id,
            roles: fragment("array_agg(? ORDER BY ? ASC)", r.slug, r.slug)},
            group_by: u.id,
            where: u.id == ^user_id
    end

    def list_users_query(page, per_page, sort_field, sort_order, filter, school_context, nil) do
      get_all_users_query()
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:first_name, sort_order)
      |> filter(filter)
      |> multiple_search(Map.get(filter, :search))
      |> paginate(page, per_page)
    end

    def list_users_query(page, per_page, sort_field, sort_order, filter, school_context, role_filter) do
      get_all_users_query(role_filter)
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:first_name, sort_order)
      |> filter(filter, school_context)
      |> multiple_search(Map.get(filter, :search))
      |> paginate(page, per_page)
    end

    def list_instructors_query(page, per_page, sort_field, sort_order, filter, school_context) do
      get_all_instructors_query()
      |> SchoolScope.scope_query(school_context)
      |> sort_by(sort_field, sort_order)
      |> sort_by(:first_name, sort_order)
      |> filter(filter, school_context)
      |> multiple_search(Map.get(filter, :search))
      |> paginate(page, per_page)
    end

    defp sort_by(query, nil, nil) do
      query
    end

    defp sort_by(query, sort_field, sort_order) do
      from g in query,
           order_by: [{^sort_order, field(g, ^sort_field)}]
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
                 where: g.id == ^value

          :archived ->
            from g in query,
                 where: g.archived == ^value

#          :archived ->
#
#            if value do
#              from q in query,
#                   where: q.archived == ^true
#            else
#              from q in query,
#                   where: q.archived == ^false
#            end

          _ ->
            query
        end
      end)
    end

    defp filter(query, %{assigned: true}=filter, %{context: %{current_user: %{id: user_id}}}=school_context) do
      queri =
        from(a in query,
        left_join: ui in UserInstructor, on: ui.instructor_id == a.id or ui.user_id == a.id,
        where: ui.user_id == ^user_id or ui.instructor_id == ^user_id)
      filter(queri, filter)
    end

    defp filter(query, filter, school_context) do
      filter(query, filter)
    end

    defp multiple_search(query, nil) do
      query
    end

    defp multiple_search(query, search) do
      count = Enum.count(search)
      search(query, search, count)
    end

    def search(query, _, count) when count == 0 do
      query
    end

    def search(query, search_items, count) when count > 0 do
      search_item = Enum.fetch!(search_items, count-1)
      search_criteria = Map.get(search_item, :search_criteria)
      search_term = Map.get(search_item, :search_term)
      case search_criteria do
        :first_name ->
            from s in query,
               where: ilike(s.first_name, ^"%#{search_term}%")

        :last_name ->
          from s in query,
               where: ilike(s.last_name, ^"%#{search_term}%")

        :email ->
          from s in query,
               where: ilike(s.email, ^"%#{search_term}%")

        :full_name ->
          from s in query,
            where: ilike(fragment("concat(?, ' ', ?)", s.first_name, s.last_name), ^"%#{search_term}%")
        _ ->
          query
      end
      |> search(search_items, count-1)
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

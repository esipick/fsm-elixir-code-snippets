defmodule FlightWeb.Admin.UserTableData do
  defstruct [:style, :rows, :page]
end

defmodule FlightWeb.Admin.UserTableDetailedRow do
  defstruct [:user_id, :name, :school, :phone_number, :next_appointment, :account_balance, :owes]
end

defmodule FlightWeb.Admin.UserTableSimpleRow do
  defstruct [:user_id, :school, :name, :phone_number]
end

defmodule FlightWeb.Admin.UserTableSimpleRowAll do
  defstruct [:user_id, :school, :name, :phone_number, :email, :roles]
end

defmodule FlightWeb.Admin.UserListData do
  defstruct [:role_label, :role, :user_table_data, :invitations, :search_term]

  alias Flight.{Accounts, Format}
  alias FlightWeb.Admin.UserListData

  def build(school_context, %{slug: "user"} = role, page_params, search_term, archived) do
    %UserListData{
      role: role,
      search_term: search_term,
      user_table_data:
        table_data_for_role(role, search_term, school_context, page_params, archived),
      invitations: []
    }
  end

  def build(school_context, role_slug, page_params, search_term, archived) do
    role = Accounts.role_for_slug(role_slug)

    if role do
      %UserListData{
        role: role,
        search_term: search_term,
        user_table_data:
          table_data_for_role(role, search_term, school_context, page_params, archived),
        invitations: []
      }
    else
      raise "Unknown role_slug: #{role_slug}"
    end
  end

  def table_data_for_role(role, search_term, school_context, page_params, archived) do
    case role.slug do
      slug when slug in ["renter", "instructor", "student"] ->
        user_table_data(:detailed, role, search_term, school_context, page_params, archived)

      slug when slug in ["admin", "dispatcher"] ->
        user_table_data(:simple, role, search_term, school_context, page_params, archived)

      slug when slug == "user" ->
        user_table_data(:simple_users, role, search_term, school_context, page_params, archived)

      _ ->
        raise "Unknown role slug: #{role.slug}"
    end
  end

  def user_table_data(
        mode,
        %{slug: "user"} = role,
        search_term,
        school_context,
        page_params,
        archived
      ) do
    page = users_page(role, search_term, school_context, page_params, archived)

    rows = simple_rows_for_all_users(page.entries)

    %FlightWeb.Admin.UserTableData{
      style: mode,
      rows: rows,
      page: page
    }
  end

  def user_table_data(mode, role, search_term, school_context, page_params, archived) do
    page = users_page(role, search_term, school_context, page_params, archived)

    rows =
      case mode do
        :detailed -> detailed_rows_for_users(page.entries)
        :simple -> simple_rows_for_users(page.entries)
        :simple_users -> simple_rows_for_all_users(page.entries)
      end

    %FlightWeb.Admin.UserTableData{
      style: mode,
      rows: rows,
      page: page
    }
  end

  def detailed_rows_for_users(users) do
    for user <- users do
      %FlightWeb.Admin.UserTableDetailedRow{
        user_id: user.id,
        school: user.school,
        name: "#{user.first_name} #{user.last_name}",
        phone_number: Format.display_phone_number(user.phone_number),
        next_appointment: "Unknown",
        account_balance: user.balance,
        owes: 500
      }
    end
  end

  def simple_rows_for_users(users) do
    for user <- users do
      %FlightWeb.Admin.UserTableSimpleRow{
        user_id: user.id,
        school: user.school,
        name: "#{user.first_name} #{user.last_name}",
        phone_number: Format.display_phone_number(user.phone_number)
      }
    end
  end

  def simple_rows_for_all_users(users) do
    for user <- users do
      %FlightWeb.Admin.UserTableSimpleRowAll{
        user_id: user.id,
        roles: user.roles,
        school: user.school,
        name: "#{user.first_name} #{user.last_name}",
        phone_number: Format.display_phone_number(user.phone_number),
        email: user.email
      }
    end
  end

  def users_page(%{slug: "user"} = role, search_term, school_context, page_params, archived) do
    if archived == :archived do
      Accounts.archived_users_with_role_query(role, search_term, school_context)
      |> Flight.Repo.paginate(page_params)
    else
      query = Accounts.users_with_role_query(role, search_term, school_context)

      case school_context.req_cookies["only_assgined_students"] do
        "true" -> Accounts.instructor_students_query(query, Map.get(page_params, :instructor_id))
        _ -> query
      end
      |> Flight.Repo.paginate(page_params)
    end
  end

  def users_page(role, search_term, school_context, page_params, archived) do
    if archived == :archived do
      Accounts.archived_users_with_role_query(role, search_term, school_context)
      |> Flight.Repo.paginate(page_params)
    else
      query = Accounts.users_with_role_query(role, search_term, school_context)

      case school_context.req_cookies["only_assgined_students"] do
        "true" -> Accounts.instructor_students_query(query, Map.get(page_params, :instructor_id))
        _ -> query
      end
      |> Flight.Repo.paginate(page_params)
    end
  end
end

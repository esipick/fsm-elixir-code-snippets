defmodule FlightWeb.Admin.UserTableData do
  defstruct [:style, :rows, :page]
end

defmodule FlightWeb.Admin.UserTableDetailedRow do
  defstruct [:user_id, :name, :school, :phone_number, :next_appointment, :account_balance, :owes]
end

defmodule FlightWeb.Admin.UserTableSimpleRow do
  defstruct [:user_id, :school, :name, :phone_number]
end

defmodule FlightWeb.Admin.UserListData do
  defstruct [:role_label, :role, :user_table_data, :invitations, :search_term]

  alias FlightWeb.Admin.UserListData

  def build(school_context, role_slug, page_params, search_term) do
    role = Flight.Accounts.role_for_slug(role_slug)

    if role do
      %UserListData{
        role: role,
        search_term: search_term,
        user_table_data: table_data_for_role(role, search_term, school_context, page_params),
        invitations: []
      }
    else
      raise "Unknown role_slug: #{role_slug}"
    end
  end

  def table_data_for_role(role, search_term, school_context, page_params) do
    case role.slug do
      slug when slug in ["renter", "instructor", "student"] ->
        user_table_data(:detailed, role, search_term, school_context, page_params)

      slug when slug in ["admin", "dispatcher"] ->
        user_table_data(:simple, role, search_term, school_context, page_params)

      _ ->
        raise "Unknown role slug: #{role.slug}"
    end
  end

  def user_table_data(mode, role, search_term, school_context, page_params) do
    page = users_page(role, search_term, school_context, page_params)

    rows =
      case mode do
        :detailed -> detailed_rows_for_users(page.entries)
        :simple -> simple_rows_for_users(page.entries)
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
        phone_number: Flight.Format.display_phone_number(user.phone_number),
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
        phone_number: Flight.Format.display_phone_number(user.phone_number)
      }
    end
  end

  def users_page(role, search_term, school_context, page_params) do
    Flight.Accounts.users_with_role_query(role, search_term, school_context)
    |> Flight.Repo.paginate(page_params)
  end
end

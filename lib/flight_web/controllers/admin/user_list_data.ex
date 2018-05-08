defmodule FlightWeb.Admin.UserTableData do
  defstruct [:style, :rows]
end

defmodule FlightWeb.Admin.UserTableDetailedRow do
  defstruct [:user_id, :name, :phone_number, :next_appointment, :account_balance, :owes]
end

defmodule FlightWeb.Admin.UserTableSimpleRow do
  defstruct [:user_id, :name, :phone_number]
end

defmodule FlightWeb.Admin.UserListData do
  defstruct [:role_label, :role, :user_table_data, :invitations]

  alias FlightWeb.Admin.UserListData

  def build(role_slug) do
    role = Flight.Accounts.role_for_slug(role_slug)

    if role do
      %UserListData{
        role: role,
        user_table_data: table_data_for_role(role),
        invitations: []
      }
    else
      raise "Unknown role_slug: #{role_slug}"
    end
  end

  def table_data_for_role(role) do
    case role.slug do
      slug when slug in ["renter", "instructor", "student"] ->
        %FlightWeb.Admin.UserTableData{
          style: :detailed,
          rows: detailed_rows_for_users(Flight.Accounts.users_with_role(role))
        }

      slug when slug in ["admin"] ->
        %FlightWeb.Admin.UserTableData{
          style: :simple,
          rows: simple_rows_for_users(Flight.Accounts.users_with_role(role))
        }

      _ ->
        raise "Unknown role slug: #{role.slug}"
    end
  end

  def detailed_rows_for_users(users) do
    for user <- users do
      %FlightWeb.Admin.UserTableDetailedRow{
        user_id: user.id,
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
        name: "#{user.first_name} #{user.last_name}",
        phone_number: "(801) 555-5555"
      }
    end
  end
end

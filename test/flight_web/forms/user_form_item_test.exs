defmodule FlightWeb.UserFormItem do
  use Flight.DataCase

  test "all editable fields produce form items" do
    user = user_fixture()

    fields =
      Flight.Accounts.Role.available_role_slugs()
      |> Enum.map(&Flight.Accounts.editable_fields_for_role_slug(&1))
      |> List.flatten()
      |> MapSet.new()

    for field <- fields do
      FlightWeb.UserForm.item(user, field)
    end
  end
end

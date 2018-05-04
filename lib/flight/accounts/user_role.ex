defmodule Flight.Accounts.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_roles" do
    belongs_to(:user, Flight.Accounts.User)
    belongs_to(:role, Flight.Accounts.Role)
  end

  @doc false
  def changeset(user_role, attrs) do
    user_role
    |> cast(attrs, [:user_id, :role_id])
    |> validate_required([])
  end
end

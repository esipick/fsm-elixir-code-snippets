defmodule Fsm.Accounts.UserRole do
    use Ecto.Schema
    import Ecto.Changeset
  
    schema "user_roles" do
      belongs_to(:user, Fsm.Accounts.User)
      belongs_to(:role, Fsm.Accounts.Role)
    end
  
    @doc false
    def changeset(user_role, attrs) do
      user_role
      |> cast(attrs, [:user_id, :role_id])
      |> validate_required([])
    end
  end
  
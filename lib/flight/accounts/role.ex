defmodule Flight.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  schema "roles" do
    field(:slug, :string)
    many_to_many(:users, Flight.Accounts.User, join_through: "user_roles")

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:slug])
    |> validate_inclusion(:slug, ["admin", "instructor", "student", "renter"])
    |> validate_required([:slug])
  end
end

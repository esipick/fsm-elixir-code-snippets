defmodule Flight.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.Accounts.Role

  @available_roles ["admin", "instructor", "student", "renter"]

  schema "roles" do
    field(:slug, :string)
    many_to_many(:users, Flight.Accounts.User, join_through: "user_roles")

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:slug])
    |> validate_inclusion(:slug, @available_roles)
    |> validate_required([:slug])
  end

  def available_roles do
    @available_roles
  end

  def admin do
    Flight.Repo.get_by(Role, slug: "admin") ||
      %Role{slug: "admin"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  def instructor do
    Flight.Repo.get_by(Role, slug: "instructor") ||
      %Role{slug: "instructor"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  def student do
    Flight.Repo.get_by(Role, slug: "student") ||
      %Role{slug: "student"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  def renter do
    Flight.Repo.get_by(Role, slug: "renter") ||
      %Role{slug: "renter"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  defmacro is_valid_role(role) do
    quote do: unquote(role) in unquote(@available_roles)
  end
end

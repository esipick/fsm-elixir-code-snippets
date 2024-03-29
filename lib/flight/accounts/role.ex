defmodule Flight.Accounts.Role do
  use Ecto.Schema
  import Ecto.Changeset

  alias Flight.Accounts.Role

  @available_role_slugs ["admin", "instructor", "student", "renter", "dispatcher", "mechanic"]

  schema "roles" do
    field(:slug, :string)
    many_to_many(:users, Flight.Accounts.User, join_through: "user_roles")

    timestamps()
  end

  @doc false
  def changeset(role, attrs) do
    role
    |> cast(attrs, [:slug])
    |> validate_inclusion(:slug, @available_role_slugs)
    |> validate_required([:slug])
  end

  def available_role_slugs do
    @available_role_slugs
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

  def dispatcher do
    Flight.Repo.get_by(Role, slug: "dispatcher") ||
      %Role{slug: "dispatcher"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  def mechanic do
    Flight.Repo.get_by(Role, slug: "mechanic") ||
      %Role{slug: "mechanic"}
      |> Role.changeset(%{})
      |> Flight.Repo.insert!()
  end

  def accessible_by("admin") do
    [:admin, :student, :renter, :instructor, :dispatcher, :mechanic]
  end

  def accessible_by("dispatcher") do
    [:student, :renter, :instructor, :dispatcher, :mechanic]
  end

  def accessible_by("instructor") do
    [:student, :instructor, :renter]
  end

  def accessible_by("mechanic") do
    [:admin, :dispatcher, :instructor]
  end

  def accessible_by(_) do
    []
  end
end

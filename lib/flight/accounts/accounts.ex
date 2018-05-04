defmodule Flight.Accounts do
  import Ecto.Query, warn: false
  alias Flight.Repo

  alias Flight.Accounts.{User, FlyerDetails, UserRole, Role, FlyerCertificate}

  require Flight.Accounts.Role

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def get_user(id, roles) do
    from(
      u in User,
      inner_join: r in assoc(u, :roles),
      where: r.slug in ^roles,
      where: u.id == ^id
    )
    |> Repo.one()
  end

  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.create_changeset(attrs)
    |> Repo.update()
  end

  def update_user_profile(%User{} = user, attrs, role_slugs, flyer_certficate_slugs) do
    user = Repo.preload(user, [:roles, :flyer_certificates])
    roles = Repo.all(from(r in Role, where: r.slug in ^role_slugs))
    certs = Repo.all(from(c in FlyerCertificate, where: c.slug in ^flyer_certficate_slugs))
    IO.inspect(flyer_certficate_slugs)

    valid_roles? = Enum.count(role_slugs) == Enum.count(roles)
    valid_certs? = Enum.count(flyer_certficate_slugs) == Enum.count(certs)

    cond do
      !valid_roles? ->
        {:error,
         Ecto.Changeset.add_error(
           User.profile_changeset(user, attrs, [], []),
           :roles,
           "are not all known: #{Enum.join(role_slugs, ", ")}"
         )}

      !valid_certs? ->
        {:error,
         Ecto.Changeset.add_error(
           User.profile_changeset(user, attrs, [], []),
           :flyer_certificates,
           "are not all known: #{Enum.join(flyer_certficate_slugs, ", ")}"
         )}

      true ->
        {:ok, result} =
          Repo.transaction(fn ->
            user
            |> User.profile_changeset(attrs, roles, certs)
            |> Repo.update()
          end)

        result
    end
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end

  #
  # Role
  #

  def assign_roles(user, roles) do
    for role <- roles do
      (Repo.get_by(UserRole, user_id: user.id, role_id: role.id) ||
         %UserRole{user_id: user.id, role_id: role.id})
      |> UserRole.changeset(%{})
      |> Repo.insert_or_update!()
    end
  end

  def users_with_role(role) do
    Repo.all(Ecto.assoc(role, :users))
  end

  def has_role?(user, role_slug) do
    user = Repo.preload(user, :roles)

    user.roles
    |> Enum.map(& &1.slug)
    |> Enum.member?(role_slug)
  end

  def has_any_role?(user, role_slugs) do
    user = Repo.preload(user, :roles)

    set =
      user.roles
      |> Enum.map(& &1.slug)
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(role_slugs))

    !Enum.empty?(set)
  end

  def role_for_slug(slug) do
    Repo.get_by(Role, slug: slug)
  end

  #
  # Certificates
  #

  def flyer_certificates() do
    Repo.all(FlyerCertificate)
  end

  def has_flyer_certificate?(user, cert_slug) do
    user = Repo.preload(user, :flyer_certificates)

    user.flyer_certificates
    |> Enum.map(& &1.slug)
    |> Enum.member?(cert_slug)
  end
end

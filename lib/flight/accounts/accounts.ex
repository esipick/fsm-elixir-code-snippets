defmodule Flight.Accounts do
  import Ecto.Query, warn: false
  alias Flight.Repo

  alias Flight.Accounts.{User, FlyerDetails, UserRole}

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
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  def assign_roles(user, roles) do
    for role <- roles do
      (Repo.get_by(UserRole, user_id: user.id, role_id: role.id) ||
         %UserRole{user_id: user.id, role_id: role.id})
      |> UserRole.changeset(%{})
      |> Repo.insert_or_update!()
    end
  end

  def has_role?(user, role) do
    user = Repo.preload(user, :roles)

    user.roles
    |> Enum.map(& &1.id)
    |> Enum.member?(role.id)
  end

  def get_flyer_details_for_user_id(user_id) do
    Repo.get_by(FlyerDetails, user_id: user_id) || FlyerDetails.default()
  end

  def set_flyer_details_for_user(attrs, user) do
    (Flight.Repo.get_by(FlyerDetails, user_id: user.id) || %FlyerDetails{user_id: user.id})
    |> FlyerDetails.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end

  def flyer_details_keys_for_roles(roles) when is_list(roles) do
  end
end

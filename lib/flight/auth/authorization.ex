defmodule Flight.Auth.Authorization do
  import Flight.Auth.Permission

  def halt_unless_user_can?(conn, permissions, permissed_func \\ nil) do
    if user_can?(conn.assigns.current_user, permissions) do
      if permissed_func do
        permissed_func.()
      else
        conn
      end
    else
      conn
      |> Plug.Conn.resp(401, "")
      |> Plug.Conn.halt()
    end
  end

  def user_can?(user, permissions) do
    for permission <- permissions do
      has_permission_slug?(user, permission_slug(permission)) && scope_checker(permission, user)
    end
    |> Enum.any?()
  end

  def has_permission_slugs?(user, slugs) when is_list(slugs) do
    is_empty? =
      permission_slugs_for_user(user)
      |> MapSet.intersection(MapSet.new(slugs))
      |> Enum.empty?()

    !is_empty?
  end

  def has_permission_slug?(user, slug) do
    MapSet.member?(permission_slugs_for_user(user), slug)
  end

  def permission_slugs_for_user(user) do
    user = Flight.Repo.preload(user, :roles)

    Enum.reduce(user.roles, MapSet.new(), fn role, map ->
      MapSet.union(map, permissions_for_role_slug(role.slug))
    end)
  end

  def role_slugs_for_permission_slug(permission_slug) do
    Flight.Accounts.Role.available_role_slugs()
    |> Enum.filter(fn role_slug ->
      role_slug
      |> permissions_for_role_slug()
      |> MapSet.member?(permission_slug)
    end)
  end

  def permissions_for_role_slug(role_slug) do
    case role_slug do
      "admin" -> admin_permission_slugs()
      "instructor" -> instructor_permission_slugs()
      "student" -> student_permission_slugs()
      "renter" -> renter_permission_slugs()
    end
  end

  def admin_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :all)
    ])
  end

  def instructor_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :all),
      permission_slug(:appointment_instructor, :modify, :personal)
    ])
  end

  def student_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :personal),
      permission_slug(:appointment_user, :modify, :personal),
      permission_slug(:appointment_student, :modify, :personal)
    ])
  end

  def renter_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :personal),
      permission_slug(:appointment_user, :modify, :personal)
    ])
  end
end

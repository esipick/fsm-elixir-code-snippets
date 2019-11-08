defmodule Flight.Auth.Authorization do
  import Flight.Auth.Permission

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
      "dispatcher" -> dispatcher_permission_slugs()
    end
  end

  def dispatcher_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :all),
      permission_slug(:users, :view, :all),
      permission_slug(:objective_score, :view, :all),
      permission_slug(:objective_score, :modify, :all),
      permission_slug(:appointment, :modify, :all),
      permission_slug(:transaction_creator, :modify, :all),
      permission_slug(:transaction_creator, :view, :all),
      permission_slug(:transaction_creator, :view, :personal),
      permission_slug(:transaction_user, :modify, :all),
      permission_slug(:transaction, :request, :all),
      permission_slug(:transaction, :modify, :all),
      permission_slug(:transaction, :view, :all),
      permission_slug(:transaction_user, :view, :all),
      permission_slug(:transaction_cash, :modify, :all),
      permission_slug(:user_protected_info, :view, :all),
      permission_slug(:push_token, :modify, :all),
      permission_slug(:unavailability, :modify, :all),
      permission_slug(:invoice, :modify, :all),
      permission_slug(:web_dashboard, :access, :all)
    ])
  end

  def admin_permission_slugs() do
    MapSet.union(
      dispatcher_permission_slugs(),
      MapSet.new([
        permission_slug(:billing_settings, :modify, :all),
        permission_slug(:admins, :modify, :all)
      ])
    )
  end

  def instructor_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :all),
      permission_slug(:appointment, :modify, :all),
      permission_slug(:appointment_instructor, :modify, :personal),
      permission_slug(:objective_score, :view, :all),
      permission_slug(:objective_score, :modify, :all),
      permission_slug(:transaction_approve, :modify, :personal),
      permission_slug(:transaction_creator, :view, :personal),
      permission_slug(:transaction_creator, :view, :all),
      permission_slug(:transaction_user, :be, :all),
      permission_slug(:transaction, :request, :all),
      permission_slug(:transaction_creator, :modify, :personal),
      permission_slug(:transaction, :view, :personal),
      permission_slug(:transaction_cash, :modify, :all),
      permission_slug(:push_token, :modify, :personal),
      permission_slug(:user_protected_info, :view, :all),
      permission_slug(:transaction_user, :view, :personal),
      permission_slug(:unavailability_instructor, :modify, :personal),
      permission_slug(:unavailability_aircraft, :modify, :all),
      permission_slug(:invoice, :modify, :all),
      permission_slug(:web_dashboard, :access, :all)
    ])
  end

  def student_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :personal),
      permission_slug(:appointment_user, :modify, :personal),
      permission_slug(:appointment_student, :modify, :personal),
      permission_slug(:objective_score, :view, :personal),
      permission_slug(:transaction_approve, :modify, :personal),
      permission_slug(:transaction_creator, :modify, :personal),
      permission_slug(:transaction, :view, :personal),
      permission_slug(:push_token, :modify, :personal),
      permission_slug(:transaction_user, :view, :personal),
      permission_slug(:web_dashboard, :access, :all)
    ])
  end

  def renter_permission_slugs() do
    MapSet.new([
      permission_slug(:users, :modify, :personal),
      permission_slug(:users, :view, :personal),
      permission_slug(:appointment_user, :modify, :personal),
      permission_slug(:objective_score, :view, :personal),
      permission_slug(:transaction_approve, :modify, :personal),
      permission_slug(:transaction_creator, :modify, :personal),
      permission_slug(:transaction, :view, :personal),
      permission_slug(:push_token, :modify, :personal),
      permission_slug(:transaction_user, :view, :personal)
    ])
  end
end

defmodule Flight.Auth.Authorization.Extensions do
  def halt_unless_user_can?(conn, permissions, permissed_func \\ nil) do
    if Flight.Auth.Authorization.user_can?(conn.assigns.current_user, permissions) do
      if permissed_func do
        permissed_func.()
      else
        conn
      end
    else
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(401, Poison.encode!(%{error: %{message: "Invalid permissions"}}))
      |> Plug.Conn.halt()
    end
  end

  def redirect_unless_user_can?(conn, permissions) do
    user = conn.assigns.current_user

    if Flight.Auth.Authorization.user_can?(user, permissions) do
      conn
    else
      conn
      |> Phoenix.Controller.put_flash(:error, "You are not authorized to perform this action.")
      |> Plug.Conn.put_status(302)
      |> Phoenix.Controller.redirect(to: FlightWeb.RoleUtil.default_redirect_path(user))
      |> Plug.Conn.halt()
    end
  end
end

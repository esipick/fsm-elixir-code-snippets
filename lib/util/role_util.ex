defmodule FlightWeb.RoleUtil do
  def default_redirect_path(user) do
    case access_level(user) do
      "admin" -> "/admin/dashboard"
      "instructor" -> "/instructor/profile"
      "student" -> "/student/profile"
      _ -> nil
    end
  end

  def access_level(user) do
    user = Flight.Repo.preload(user, :roles)
    roles = Enum.map(user.roles, fn r -> r.slug end)

    cond do
      Enum.member?(roles, "admin") || Enum.member?(roles, "dispatcher") ->
        "admin"

      Enum.member?(roles, "instructor") ->
        "instructor"

      Enum.member?(roles, "student") ->
        "student"

      true ->
        nil
    end
  end
end

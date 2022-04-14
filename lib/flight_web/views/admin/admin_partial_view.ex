defmodule FlightWeb.Admin.PartialView do
  use FlightWeb, :view

  def user_roles_meta_tag(conn) do
    case Map.get(conn.assigns, :current_user) do
      %Flight.Accounts.User{} = user ->
        user = Flight.Repo.preload(user, :roles)

        roles =
          user.roles
          |> Enum.map(& &1.slug)
          |> Enum.join(", ")

        tag(:meta, name: "roles", content: roles)

      _ ->
        nil
    end
  end

  def user_roles(user) do

    user = Flight.Repo.preload(user, :roles)
    roles =
      user.roles
      |> Enum.map(& &1.slug)
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(", ")
    roles
  end
end

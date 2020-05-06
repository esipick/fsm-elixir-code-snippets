defmodule FlightWeb.Admin.PartialView do
  use FlightWeb, :view

  def user_id_meta_tag(conn) do
    with %Flight.Accounts.User{} = user <- Map.get(conn.assigns, :current_user),
         false <- Flight.Accounts.has_role?(Flight.Repo.preload(user, :roles), "admin") do
      tag(:meta, name: "user_id", content: user.id)
    else
      _ ->
        nil
    end
  end
end

defmodule FlightWeb.API.RolesView do
  use FlightWeb, :view

  def render("index.json", %{roles: roles}) do
    %{
      data: render_many(roles, __MODULE__, "role.json", as: :role)
    }
  end

  def render("role.json", %{role: role}) do
    %{
      id: role.id,
      slug: role.slug
    }
  end
end

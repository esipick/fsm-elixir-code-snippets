defmodule FlightWeb.Admin.InvitationView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  def add_user_label_for_role(role) do
    case role.slug do
      "admin" -> "Add an #{singular_label_for_role(role)}"
      _ -> "Add a #{singular_label_for_role(role)}"
    end
  end
end

defmodule FlightWeb.Instructor.StudentView do
  use FlightWeb, :view

  import FlightWeb.Admin.UserView, except: [render: 2, template_not_found: 2]
  import FlightWeb.Shared.ProfileView
  import FlightWeb.ViewHelpers
  import Scrivener.HTML
  alias Flight.Accounts
end

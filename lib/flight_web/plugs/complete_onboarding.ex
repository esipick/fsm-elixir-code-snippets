defmodule FlightWeb.CompleteOnboarding do
  import Plug.Conn
  import Flight.OnboardingUtil

  alias FlightWeb.Router.Helpers, as: Routes
  alias Flight.{Repo, SchoolScope, Accounts}

  def init(_), do: nil

  def call(conn, _) do
    superadmin = Accounts.is_superadmin?(conn.assigns.current_user)
    school = SchoolScope.get_school(conn) |> Repo.preload(:school_onboarding)

    if superadmin || onboarding_completed?(school) do
      conn
    else
      step = current_step(school)

      conn
      |> Phoenix.Controller.redirect(to: Routes.settings_path(conn, :show, tab: step))
      |> halt()
    end
  end
end

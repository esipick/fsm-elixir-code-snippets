defmodule FlightWeb.CompleteOnboarding do
  import Plug.Conn
  import Flight.OnboardingUtil

  alias FlightWeb.Router.Helpers, as: Routes
  alias Flight.{Repo, SchoolScope, Accounts.School}

  def init(_), do: nil

  def call(conn, _) do
    school = SchoolScope.get_school(conn) |> Repo.preload(:school_onboarding)

    if onboarding_completed?(school) do
      conn
    else
      step = current_step(school)

      conn
      |> Phoenix.Controller.redirect(to: Routes.settings_path(conn, :show, tab: step))
      |> halt()
    end
  end
end

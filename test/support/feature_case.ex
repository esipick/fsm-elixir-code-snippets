defmodule FlightWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias Flight.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      import Wallaby.Query

      import FlightWeb.Router.Helpers
      import Flight.AccountsFixtures
      import Flight.SchedulingFixtures
      import Flight.BillingFixtures
      import FlightWeb.FeatureHelpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Flight.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Flight.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Flight.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end

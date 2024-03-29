ExUnit.start()
ExUnit.configure(exclude: [:integration])

Ecto.Adapters.SQL.Sandbox.mode(Flight.Repo, :manual)

if System.get_env("CI") do
  {:ok, _} = Application.ensure_all_started(:wallaby)

  Application.put_env(:wallaby, :base_url, FlightWeb.Endpoint.url())
end

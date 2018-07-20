ExUnit.start()
ExUnit.configure(exclude: [:integration])

Ecto.Adapters.SQL.Sandbox.mode(Flight.Repo, :manual)

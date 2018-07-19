use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :flight, FlightWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :flight, Flight.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "flight_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :bcrypt_elixir, log_rounds: 4

config :flight, :user_token_salt, "gwfyeA8B5"

config :flight, Flight.Mailer, adapter: Bamboo.TestAdapter

config :stripity_stripe,
  api_key: "sk_test_ZHmnpsn2AcEeUNMVWj5ueuZ7",
  connect_client_id: "ca_DDbtUXP12O6p6UPiLSHMuC5r66cSyNS0"

config :flight, :push_service_client, Mondo.PushService.MockClient

config :stripity_stripe, :pool_options,
  timeout: 5_000,
  max_connections: 10

config :appsignal, :config, active: false

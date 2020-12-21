use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :flight, FlightWeb.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
#config :flight, Flight.Repo,
#  username: "admin",
#  password: "123456",
#  database: "flight_test",
#  hostname: "localhost",
#  pool: Ecto.Adapters.SQL.Sandbox,
#  ownership_timeout: 600_000

# Connect to staging database
config :flight, Flight.Repo,
  username: "bgxmltqexmsbbt",
  password: "f745da74c253a3ff78fc4a7728e6612d8fb3dd16e1923943e02c554a294fa2dc",
  database: "d3lugdu8a44rbb",
  hostname: "ec2-174-129-22-84.compute-1.amazonaws.com",
  queue_interval: 3000_000,
  port: 5432,
  pool_size: 10,
  ssl: true

config :bcrypt_elixir, log_rounds: 4

config :flight, :user_token_salt, "gwfyeA8B5"
config :flight, :webhook_token, "abc"
config :flight, :platform_fee_amount, 5000
config :flight, :stripe_publishable_key, "pk_test_PKZCFv4SUII1gBu5wTeYw5OV"

config :flight, Flight.Mailer, adapter: Bamboo.TestAdapter

config :stripity_stripe,
  api_key: "sk_test_j56pdGNCUxL66RMEP7mFdyNQ",
  connect_client_id: "ca_DGcV6SWq1ghyws1HwmcAHLgPldcHNisy"

config :flight, :push_service_client, Mondo.PushService.MockClient

config :stripity_stripe, :pool_options,
  timeout: 5_000,
  max_connections: 10

config :appsignal, :config, active: false

config :wallaby, driver: Wallaby.Experimental.Chrome

# Visual testing: on - false, off - true
config :wallaby,
  chromedriver: [
    headless: true
  ]

config :wallaby, screenshot_on_failure: true, js_errors: false

config :flight, :sql_sandbox, true

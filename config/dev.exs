use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :flight, FlightWeb.Endpoint,
  http: [port: System.get_env("PORT") || 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/brunch/bin/brunch",
      "watch",
      "--stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# config :stripy,
#   secret_key: "sk_test_ZHmnpsn2AcEeUNMVWj5ueuZ7",
#   endpoint: "https://api.stripe.com/v1/",
#   version: "2018-05-21",
#   httpoison: [recv_timeout: 5000, timeout: 8000]

config :stripity_stripe, api_key: "sk_test_ZHmnpsn2AcEeUNMVWj5ueuZ7"
config :flight, :stripe_webhook_secret, "whsec_GRniVd07D9yl84sImiK3ijoy1JE6gqwf"
config :flight, :stripe_livemode, false

config :stripity_stripe, :pool_options,
  timeout: 5_000,
  max_connections: 10

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# command from your terminal:
#
#     openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
#
# The `http:` config above can be replaced with:
#
#     https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :flight, FlightWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/flight_web/views/.*(ex)$},
      ~r{lib/flight_web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :flight, Flight.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "flight_dev",
  hostname: "localhost",
  pool_size: 10

config :flight, :user_token_salt, "gwfyeA8B5"

config :flight, Flight.Mailer, adapter: Bamboo.LocalAdapter

config :appsignal, :config, active: false

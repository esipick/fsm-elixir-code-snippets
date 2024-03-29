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
    ],
    yarn: [
      "watch_webpack",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

# config :stripy,
#   secret_key: "sk_test_ZHmnpsn2AcEeUNMVWj5ueuZ7",
#   endpoint: "https://api.stripe.com/v1/",
#   version: "2018-05-21",
#   httpoison: [recv_timeout: 5000, timeout: 8000]

config :stripity_stripe,
  api_key: "sk_test_j56pdGNCUxL66RMEP7mFdyNQ",
  connect_client_id: "ca_DGcV6SWq1ghyws1HwmcAHLgPldcHNisy"

config :flight, :stripe_publishable_key, "pk_test_PKZCFv4SUII1gBu5wTeYw5OV"
config :flight, :stripe_webhook_secret, "whsec_IgVFTyMuy8E9PAZ5HmOFBJPpgWAz82yP"
config :flight, :stripe_livemode, false

case(Map.fetch(System.get_env(), "SUPERADMIN_IDS")) do
  {:ok, keys} ->
    config :flight,
      superadmin_ids:
        keys
        |> String.split(",")
        |> Enum.map(&String.to_integer/1)

  _ ->
    config :flight, superadmin_ids: [1, 7]
end

case(Map.fetch(System.get_env(), "LMS_BETA_SCHOOLS_IDS")) do
  {:ok, keys} ->
    config :flight,
           lms_beta_schools_ids:
             keys
             |> String.split(",")
             |> Enum.map(&String.to_integer/1)

  _ ->
    config :flight, lms_beta_schools_ids: [11, 7]
end

config :flight, :webhook_token, "abc"
config :flight, :platform_fee_amount, 5000

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
  username: "postgres",
  password: "postgres",
  database: "flight_dev",
  hostname: "localhost",
  pool_size: 10

config :flight, :user_token_salt, "gwfyeA8B5"

# config :flight, Flight.Mailer, adapter: Bamboo.LocalAdapter

config :flight, Flight.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: "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"

config :appsignal, :config, active: false
config :flight, :lms_endpoint, System.get_env("LMS_ENDPOINT") || "https://moodlenew.esipick.com"
config :flight, :webtoken_key, System.get_env("WEBTOKEN_KEY") || "FSMM"
config :flight, :webtoken_secret_key, System.get_env("WEBTOKEN_SECRET_KEY") || ".jG<T9qX6sNk3.Z3"
config :flight, :per_course_price, String.to_integer(System.get_env("PER_COURSE_PRICE") || "10")
config :flight, :monthly_invoice_creator, String.to_integer(System.get_env("MONTHLY_INVOICE_CREATOR") || "1")
config :flight, :enable_lms_for_all, System.get_env("ENABLE_LMS_FOR_ALL") || "YES"
config :flight, :appointment_unavailability_template_id, System.get_env("APPOINTMENT_UNAVAILABILITY_TEMPLATE_ID") || "d-54653246c8204f0bb62d31bc85ebdf09"

# upload file config
config :flight, :file_size, String.to_integer(System.get_env("FILE_SIZE") || "10485760")

config :logger, level: :debug

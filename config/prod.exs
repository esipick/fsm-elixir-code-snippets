use Mix.Config

# For production, we often load configuration from external
# sources, such as your system environment. For this reason,
# you won't find the :http configuration below, but set inside
# FlightWeb.Endpoint.init/2 when load_from_system_env is
# true. Any dynamic configuration should be done there.
#
# Don't forget to configure the url host to something meaningful,
# Phoenix uses this information when generating URLs.
#
# Finally, we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
host =
  Map.fetch!(System.get_env(), "FLIGHT_WEB_BASE_URL")
  |> String.replace("https://", "")

config :flight, FlightWeb.Endpoint,
  load_from_system_env: true,
  url: [scheme: "https:", host: host, port: 443],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

config :flight, Flight.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true

config :flight, :user_token_salt, Map.fetch!(System.get_env(), "USER_TOKEN_SALT")

# Do not print debug messages in production
config :logger, level: :info

config :flight, Flight.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: System.get_env("SENDGRID_API_KEY")

config :stripity_stripe,
  api_key: Map.fetch!(System.get_env(), "STRIPE_SECRET_KEY"),
  connect_client_id: Map.fetch!(System.get_env(), "STRIPE_CONNECT_CLIENT_ID")

config :flight, :stripe_publishable_key, Map.fetch!(System.get_env(), "STRIPE_PUBLISHABLE_KEY")

config :flight, stripe_webhook_secret: Map.fetch!(System.get_env(), "STRIPE_WEBHOOK_SECRET")
config :flight, stripe_livemode: Map.fetch!(System.get_env(), "STRIPE_LIVEMODE") == "true"

config :flight,
       :platform_fee_amount,
       Map.fetch!(System.get_env(), "PLATFORM_FEE_AMOUNT") |> String.to_integer()

config :flight,
  superadmin_ids:
    Map.fetch!(System.get_env(), "SUPERADMIN_IDS")
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)

config :flight,
       lms_beta_schools_ids:
         Map.fetch!(System.get_env(), "LMS_BETA_SCHOOLS_IDS")
         |> String.split(",")
         |> Enum.map(&String.to_integer/1)

config :flight, :webhook_token, Map.fetch!(System.get_env(), "WEBHOOK_TOKEN")

config :stripity_stripe, :pool_options,
  timeout: 5_000,
  max_connections: 10

config :flight, :aws_apns_application_arn, Map.fetch!(System.get_env(), "AWS_SNS_APNS_ARN")
config :flight, :lms_endpoint, System.get_env("LMS_ENDPOINT") || "https://moodlenew.esipick.com"
config :flight, :webtoken_key, System.get_env("WEBTOKEN_KEY") || "FSM"
config :flight, :webtoken_secret_key, System.get_env("WEBTOKEN_SECRET_KEY") || ".jG<T9qX6sNk3.Z3"
config :flight, :per_course_price, String.to_integer(System.get_env("PER_COURSE_PRICE") || "10")
config :flight, :monthly_invoice_creator, String.to_integer(System.get_env("MONTHLY_INVOICE_CREATOR") || "1")
config :flight, :enable_lms_for_all, System.get_env("ENABLE_LMS_FOR_ALL") || "NO"
config :flight, :appointment_unavailability_template_id, System.get_env("APPOINTMENT_UNAVAILABILITY_TEMPLATE_ID") || "d-54653246c8204f0bb62d31bc85ebdf09"

# upload file config
config :flight, :file_size, String.to_integer(System.get_env("FILE_SIZE") || "10485760")

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :flight, FlightWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :flight, FlightWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.

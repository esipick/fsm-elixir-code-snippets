# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :flight, ecto_repos: [Flight.Repo]
config :flight, :web_base_url, System.get_env("FLIGHT_WEB_BASE_URL") || "http://localhost:4000"

# Configures the endpoint
config :flight, FlightWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "XAxVUTVRvUisJuX2C5Ylc3nzjjv3Eg9Ih4WkjCjIUMocb43C9p3dNe496k7ns9i3",
  render_errors: [view: FlightWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Flight.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :flight, FlightWeb.Endpoint, instrumenters: [Appsignal.Phoenix.Instrumenter]

config :phoenix, :template_engines,
  eex: Appsignal.Phoenix.Template.EExEngine,
  exs: Appsignal.Phoenix.Template.ExsEngine

config :flight, Flight.Repo, loggers: [Appsignal.Ecto, Ecto.LogEntry]

import_config "appsignal.exs"

aws_access_key = "AKIAIETEFGSBHU6Z7KJQ"
aws_secret_key = "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"

config :flight,
       :aws_apns_application_arn,
       "arn:aws:sns:us-east-1:699782583642:app/APNS_SANDBOX/fsm-apns-dev"

config :flight, :aws_credentials,
  access_key: aws_access_key,
  secret_key: aws_secret_key

config :ex_aws,
  access_key_id: aws_access_key,
  secret_access_key: aws_secret_key,
  region: "us-east-1"

config :flight, :push_service_client, Mondo.PushService.Client

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

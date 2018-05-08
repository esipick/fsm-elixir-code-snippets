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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

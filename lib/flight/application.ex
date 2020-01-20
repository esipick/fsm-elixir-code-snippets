defmodule Flight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Flight.Repo,
      # Start the Endpoint (http/https)
      FlightWeb.Endpoint
      # Start a worker by calling: Flight.Worker.start_link(arg)
      # {Flight.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Flight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    FlightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

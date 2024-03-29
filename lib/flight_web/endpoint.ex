defmodule FlightWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :flight
  use Appsignal.Phoenix

  if Application.get_env(:flight, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  socket("/socket", FlightWeb.UserSocket,
    websocket: true,
    longpoll: false
  )

  if Application.get_env(:waffle, :storage) == Waffle.Storage.Local do
    plug(
      Plug.Static,
      at: "/uploads",
      from: Path.expand("./uploads"),
      gzip: false
    )
  end

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :flight,
    gzip: true,
    only: ~w(css fonts images js favicon.ico robots.txt uploads)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, {:multipart, length: 200_000_000}, :json],
    pass: ["*/*"],
    body_reader: {Flight.WebhookPayloads, :read_body, []},
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_flight_key",
    signing_salt: "rP/4UMR4"
  )

  plug(FlightWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end

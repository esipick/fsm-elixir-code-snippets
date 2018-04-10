defmodule FlightWeb.Router do
  use FlightWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", FlightWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  scope "/api", FlightWeb do
    pipe_through(:api)

    post("/login", SessionController, :login)
    resources("/users", UserController, only: [:show])
  end
end

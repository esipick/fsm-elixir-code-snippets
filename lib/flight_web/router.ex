defmodule FlightWeb.Router do
  use FlightWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :no_layout do
    plug(:put_layout, false)
  end

  pipeline :admin_layout do
    plug(:put_layout, {FlightWeb.LayoutView, :admin})
  end

  pipeline :admin_authenticate do
    plug(FlightWeb.AuthenticateWebUser, roles: ["admin"])
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", FlightWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  # Unauthenticated pages
  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :no_layout])
    get("/login", SessionController, :login)
    post("/login", SessionController, :login_submit)
  end

  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :admin_layout, :admin_authenticate])
    get("/dashboard", PageController, :dashboard)

    resources("/users", UserController, only: [:index, :show, :edit, :update])
  end

  scope "/api", FlightWeb do
    pipe_through(:api)

    post("/login", SessionController, :api_login)

    resources("/users", UserController, only: [:show, :update]) do
      get("/flyer_details", FlyerDetailController, :show)
      put("/flyer_details", FlyerDetailController, :update)
    end
  end
end

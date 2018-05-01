defmodule FlightWeb.Router do
  use FlightWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :admin_layout do
    plug(:put_layout, {FlightWeb.LayoutView, :admin})
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", FlightWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :admin_layout])
    get("/dashboard", PageController, :dashboard)
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

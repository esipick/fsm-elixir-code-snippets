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
    pipe_through([:browser, :no_layout])

    get("/", PageController, :index)
    get("/invitations/:token", InvitationController, :accept)
    get("/invitations/:token/success", InvitationController, :accept_success)
    post("/invitations/:token", InvitationController, :accept_submit)
  end

  # Unauthenticated admin pages
  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :no_layout])
    get("/login", SessionController, :login)
    post("/login", SessionController, :login_submit)
  end

  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :admin_layout, :admin_authenticate])
    get("/dashboard", PageController, :dashboard)

    resources("/users", UserController, only: [:index, :show, :edit, :update])

    resources("/invitations", InvitationController, only: [:create, :index]) do
      post("/resend", InvitationController, :resend)
      get("/resend", InvitationController, :resend)
    end

    resources(
      "/aircrafts",
      AircraftController,
      only: [:create, :update, :edit, :show, :index, :new]
    )
  end

  scope "/api", FlightWeb do
    pipe_through(:api)

    post("/login", SessionController, :api_login)

    resources("/users", UserController, only: [:show, :update])
  end

  if Mix.env() == :dev do
    forward("/email_inbox", Bamboo.EmailPreviewPlug)
  end
end

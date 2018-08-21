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

  pipeline :webhooks_authenticate do
    plug(FlightWeb.AuthenticateWebhook)
  end

  pipeline :admin_metrics_namespace do
    plug(AppsignalNamespace)
  end

  pipeline :api_authenticate do
    plug(FlightWeb.AuthenticateApiUser)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  ###
  # Admin Routes
  ###

  scope "/", FlightWeb do
    # Use the default browser stack
    pipe_through([:browser, :no_layout])

    get("/", PageController, :index)
    get("/invitations/:token", InvitationController, :accept)
    get("/invitations/:token/success", InvitationController, :accept_success)
    post("/invitations/:token", InvitationController, :accept_submit)

    get("/school_invitations/:token", SchoolInvitationController, :accept)
    post("/school_invitations/:token", SchoolInvitationController, :accept_submit)
    
    get("/forgot", PageController, :forgot)
    get("/reset", PageController, :reset)
    
  end

  scope "/webhooks", FlightWeb do
    pipe_through([:webhooks_authenticate])

    post(
      "/upcoming_appointment_notifications",
      WebhookController,
      :upcoming_appointment_notifications
    )

    post(
      "/outstanding_payments_notifications",
      WebhookController,
      :outstanding_payments_notifications
    )
  end

  # Unauthenticated admin pages
  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :no_layout, :admin_metrics_namespace])

    get("/login", SessionController, :login)
    post("/login", SessionController, :login_submit)
  end

  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :admin_layout, :admin_authenticate, :admin_metrics_namespace])

    get("/", PageController, :root)

    get("/dashboard", PageController, :dashboard)

    get("/logout", SessionController, :logout)

    resources("/schools", SchoolController, only: [:index, :show, :edit, :update])
    
    resources("/reports", ReportsController, only: [:index])
    
    scope("/reports") do
      get("/students", ReportsController, :students)
      get("/renters", ReportsController, :renters)
      get("/instructors", ReportsController, :instructors)
      get("/aircraft", ReportsController, :aircraft)
    end
    

    resources("/users", UserController, only: [:index, :show, :edit, :update]) do
      post("/add_funds", UserController, :add_funds)
    end

    resources("/transactions", TransactionController, only: []) do
      post("/cancel", TransactionController, :cancel)
    end

    resources("/settings", SettingsController, only: [:show, :update], singleton: true)

    get("/stripe_connect", StripeController, :connect)

    resources("/schedule", ScheduleController, only: [:index, :show, :edit])
    
    resources("/courses", CoursesController, only: [:index, :edit])

    resources("/invitations", InvitationController, only: [:create, :index]) do
      post("/resend", InvitationController, :resend)
      get("/resend", InvitationController, :resend)
    end

    resources("/school_invitations", SchoolInvitationController, only: [:create, :index]) do
      post("/resend", SchoolInvitationController, :resend)
      get("/resend", SchoolInvitationController, :resend)
    end

    resources(
      "/aircrafts",
      AircraftController,
      only: [:create, :update, :edit, :show, :index, :new]
    ) do
      resources("/inspections", InspectionController, only: [:create, :new])
    end

    resources("/inspections", InspectionController, only: [:edit, :update, :delete])
  end

  ###
  # API Routes
  ###
  scope "/api", FlightWeb.API do
    post("/stripe_events", StripeController, :stripe_events)
  end

  scope "/api", FlightWeb.API do
    pipe_through(:api)

    post("/login", SessionController, :api_login)
  end

  scope "/api", FlightWeb.API do
    pipe_through([:api, :api_authenticate])

    resources("/users", UserController, only: [:show, :update, :index]) do
      get("/form_items", UserController, :form_items)
      resources("/push_tokens", PushTokenController, only: [:create])
    end

    resources("/aircrafts", AircraftController, only: [:index, :show])

    resources("/transactions", TransactionController, only: [:create, :index, :show]) do
      post("/approve", TransactionController, :approve)
    end

    post("/transactions/preview", TransactionController, :preview)

    post(
      "/transactions/preferred_payment_method",
      TransactionController,
      :preferred_payment_method
    )

    post("/stripe_ephemeral_keys", TransactionController, :ephemeral_keys)

    post("/objective_scores", ObjectiveScoreController, :create)
    get("/objective_scores", ObjectiveScoreController, :index)
    delete("/objective_scores", ObjectiveScoreController, :delete)

    post("/objective_notes", ObjectiveNoteController, :create)
    get("/objective_notes", ObjectiveNoteController, :index)
    delete("/objective_notes", ObjectiveNoteController, :delete)

    get("/appointments/availability", AppointmentController, :availability)

    resources(
      "/appointments",
      AppointmentController,
      only: [:create, :index, :update, :show, :delete]
    )

    resources("/courses", CourseController, only: [:index])
  end

  if Mix.env() == :dev do
    forward("/email_inbox", Bamboo.EmailPreviewPlug)
  end
end

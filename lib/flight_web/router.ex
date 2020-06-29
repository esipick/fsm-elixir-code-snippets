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

  pipeline :student_layout do
    plug(:put_layout, {FlightWeb.LayoutView, :student})
  end

  pipeline :admin_authenticate do
    plug(FlightWeb.AuthenticateWebUser, roles: ["admin", "dispatcher"])
  end

  pipeline :student_authenticate do
    plug(FlightWeb.AuthenticateWebUser, roles: ["student"])
  end

  pipeline :instructor_authenticate do
    plug(FlightWeb.AuthenticateWebUser, roles: ["instructor"])
  end

  pipeline :web_user_authenticate do
    plug(FlightWeb.AuthenticateWebUser, roles: ["admin", "dispatcher", "student", "instructor"])
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

  pipeline :complete_onboarding do
    plug(FlightWeb.CompleteOnboarding)
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

    get("/forgot_password", PasswordController, :forgot)
    post("/forgot_password", PasswordController, :forgot_submit)
    get("/reset_password", PasswordController, :reset)
    post("/reset_password", PasswordController, :reset_submit)

    get("/login", SessionController, :login)
    post("/login", SessionController, :login_submit)
    get("/logout", SessionController, :logout)
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
  scope "/admin", FlightWeb do
    pipe_through([:browser, :no_layout, :admin_metrics_namespace])

    get("/login", SessionController, :login)
    post("/login", SessionController, :login_submit)
  end

  scope "/student", FlightWeb.Student do
    pipe_through([:browser, :admin_layout, :student_authenticate, :admin_metrics_namespace])

    resources("/schedule", ScheduleController, only: [:index, :show, :edit])

    resources("/profile", ProfileController, only: [:show, :edit, :update], singleton: true) do
      put("/update_card", ProfileController, :update_card)
    end
  end

  scope "/instructor", FlightWeb.Instructor do
    pipe_through([:browser, :admin_layout, :instructor_authenticate, :admin_metrics_namespace])

    resources("/schedule", ScheduleController, only: [:index, :show, :edit])
    resources("/profile", ProfileController, only: [:show, :edit, :update], singleton: true)

    resources("/students", StudentController, only: [:index, :show, :edit, :update]) do
      post("/add_funds", StudentController, :add_funds)
    end
  end

  scope("/billing", FlightWeb.Billing, as: :billing) do
    pipe_through([
      :browser,
      :admin_layout,
      :web_user_authenticate,
      :admin_metrics_namespace,
      :complete_onboarding
    ])

    resources("/invoices", InvoiceController, only: [:index, :new, :edit, :show, :delete])
    resources("/bulk_invoices", BulkInvoiceController, only: [:new])
    resources("/transactions", TransactionController, only: [:index, :show])
  end

  scope "/admin", FlightWeb.Admin do
    pipe_through([
      :browser,
      :admin_layout,
      :admin_authenticate,
      :admin_metrics_namespace,
      :complete_onboarding
    ])

    get("/", PageController, :root)

    get("/dashboard", PageController, :dashboard)

    resources("/schools", SchoolController, only: [:index, :show, :delete])

    resources("/reports", ReportsController, only: [:index])

    resources("/communication", CommunicationController, only: [:index, :new, :create])

    scope("/reports") do
      get("/detail", ReportsController, :detail)
    end

    resources("/users", UserController, only: [:index, :show, :edit, :update, :delete]) do
      post("/add_funds", UserController, :add_funds)
      get("/restore", UserController, :restore)
      put("/update_card", UserController, :update_card)
    end

    resources("/transactions", TransactionController, only: []) do
      post("/cancel", TransactionController, :cancel)
    end

    resources("/schedule", ScheduleController, only: [:index, :show, :edit])

    resources("/courses", CoursesController, only: [:index, :show, :edit, :new, :create])
    resources("/courses/lessons", LessonsController, only: [:show, :new, :create])

    resources(
      "/courses/lessons/objectives",
      ObjectivesController,
      only: [:index, :edit, :new, :create]
    )

    resources("/invitations", InvitationController, only: [:create, :index, :delete]) do
      post("/resend", InvitationController, :resend)
      get("/resend", InvitationController, :resend)
    end

    resources("/school_invitations", SchoolInvitationController, only: [:create, :index, :delete]) do
      post("/resend", SchoolInvitationController, :resend)
      get("/resend", SchoolInvitationController, :resend)
    end
  end

  # Onboarding admin pages
  scope "/admin", FlightWeb.Admin do
    pipe_through([:browser, :admin_layout, :admin_authenticate, :admin_metrics_namespace])

    get("/stripe_connect", StripeController, :connect)

    resources("/settings", SettingsController, only: [:show, :update])
    resources("/settings", SettingsController, only: [:show, :update], singleton: true)

    resources("/aircrafts", AircraftController) do
      resources("/inspections", InspectionController, only: [:create, :new])
    end

    resources("/simulators", SimulatorController) do
      resources("/inspections", InspectionController, only: [:create, :new])
    end

    resources("/rooms", RoomController)

    resources("/inspections", InspectionController, only: [:edit, :update, :delete])
  end

  ###
  # API Routes
  ###
  scope "/api", FlightWeb.API do
    post("/stripe_events", StripeController, :stripe_events)
    get("/ios_app_version", IosAppVersionController, :index)
  end

  scope "/api", FlightWeb.API do
    pipe_through(:api)

    post("/login", SessionController, :api_login)
  end

  scope "/api", FlightWeb.API do
    pipe_through([:api, :api_authenticate])

    resources("/roles", RolesController, only: [:index])

    get("/school", SchoolController, :index, as: :school)

    get("/users/autocomplete", UserController, :autocomplete, as: :autocomplete)
    get("/users/by_role", UserController, :by_role, as: :by_role)

    resources("/users", UserController, only: [:show, :create, :update, :index]) do
      get("/form_items", UserController, :form_items)
      patch("/change_password", UserController, :change_password)
      put("/change_password", UserController, :change_password)
      resources("/documents", DocumentController, only: [:create, :delete, :index, :update])
      resources("/push_tokens", PushTokenController, only: [:create])
      resources("/cards", CardController, only: [:create, :update, :delete])
    end

    get("/aircrafts/autocomplete", AircraftController, :autocomplete, as: :autocomplete)
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

    resources(
      "/unavailabilities",
      UnavailabilityController,
      only: [:create, :index, :update, :show, :delete]
    )

    get("/invoices/appointments", InvoiceController, :appointments, as: :appointments)
    get("/invoices/payment_options", InvoiceController, :payment_options, as: :payment_options)

    get("/invoices/from_appointment/:appointment_id", InvoiceController, :get_from_appointment,
      as: :get_from_appointment
    )

    post("/invoices/from_appointment/:appointment_id", InvoiceController, :from_appointment,
      as: :from_appointment
    )

    post("/invoices/calculate", InvoiceController, :calculate, as: :calculate_invoice)

    resources("/invoices", InvoiceController, only: [:index, :show, :create, :update, :delete])
    resources("/bulk_invoices", BulkInvoiceController, only: [:create])

    resources("/courses", CourseController, only: [:index])

    scope "/invoices", Invoices do
      get("/line_items/extra_options", LineItemController, :extra_options)

      scope "/:school_id" do
        resources("/custom_line_items", CustomLineItemController,
          only: [:create, :delete, :update]
        )
      end
    end
  end

  if Mix.env() == :dev do
    forward("/email_inbox", Bamboo.EmailPreviewPlug)
  end
end

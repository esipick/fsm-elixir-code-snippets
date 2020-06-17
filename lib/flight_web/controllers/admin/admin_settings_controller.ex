defmodule FlightWeb.Admin.SettingsController do
  use FlightWeb, :controller
  import Flight.Repo
  import Flight.OnboardingUtil

  alias FlightWeb.Router.Helpers, as: Routes

  alias Flight.{
    Accounts,
    Auth.Permission,
    Billing.InvoiceCustomLineItem,
    Accounts.ProgressSchoolOnboarding
  }

  plug(:get_school)
  plug(:authorize_admin when action in [:show])

  def show(conn, %{"tab" => "contact"}) do
    changeset = Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(conn, "show.html",
      changeset: changeset,
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :contact
    )
  end

  def show(conn, %{"tab" => "payment"}) do
    render(conn, "show.html", tab: :payment, school: conn.assigns.school, hide_school_info: true)
  end

  def show(%{assigns: %{school: school}} = conn, %{"tab" => "billing"}) do
    changeset = Accounts.School.admin_changeset(school, %{})

    custom_line_items =
      InvoiceCustomLineItem.get_custom_line_items(school)
      |> Enum.map(fn custom_line_item ->
        %{
          description: custom_line_item.description,
          default_rate: custom_line_item.default_rate,
          id: custom_line_item.id,
          taxable: custom_line_item.taxable,
          deductible: custom_line_item.deductible
        }
      end)

    props = %{custom_line_items: custom_line_items, school_id: school.id}

    render(conn, "show.html",
      changeset: changeset,
      hide_school_info: true,
      props: props,
      school: conn.assigns.school,
      tab: :billing
    )
  end

  def show(conn, %{"tab" => "profile"}) do
    changeset = Accounts.School.admin_changeset(conn.assigns.school, %{})

    render(conn, "show.html",
      changeset: changeset,
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :profile
    )
  end

  def show(conn, %{"tab" => "assets"} = params) do
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftListData.build(conn, page_params)

    render(conn, "show.html",
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :assets,
      asset: :aircraft,
      data: data,
      redirect_back_to: redirect_back_to_path(conn)
    )
  end

  def show(conn, %{"tab" => "assets_aircraft"} = params) do
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.AircraftListData.build(conn, page_params)

    render(conn, "show.html",
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :assets,
      asset: :aircraft,
      data: data,
      redirect_back_to: redirect_back_to_path(conn)
    )
  end

  def show(conn, %{"tab" => "assets_simulator"} = params) do
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.SimulatorListData.build(conn, page_params)

    render(conn, "show.html",
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :assets,
      asset: :simulator,
      data: data,
      redirect_back_to: redirect_back_to_path(conn)
    )
  end

  def show(conn, %{"tab" => "assets_room"} = params) do
    page_params = FlightWeb.Pagination.params(params)
    data = FlightWeb.Admin.RoomListData.build(conn, page_params)

    render(conn, "show.html",
      hide_school_info: true,
      school: conn.assigns.school,
      tab: :assets,
      asset: :room,
      data: data,
      redirect_back_to: redirect_back_to_path(conn)
    )
  end

  def show(conn, %{"step_back" => step_back}) do
    {_school, tab} = ProgressSchoolOnboarding.run(conn.assigns.school, %{step_back: step_back})

    conn
    |> redirect(to: Routes.settings_path(conn, :show, tab: tab))
  end

  def show(conn, %{"step_forward" => "true"}) do
    school = conn.assigns.school
    step = current_step(school)
    {school, tab} = ProgressSchoolOnboarding.run(school, %{redirect_tab: step})

    if onboarding_completed?(school) do
      conn
      |> redirect(to: Routes.page_path(conn, :dashboard))
    else
      conn
      |> redirect(to: Routes.settings_path(conn, :show, tab: tab))
    end
  end

  def show(%{assigns: %{school: school}} = conn, _) do
    changeset = Accounts.School.admin_changeset(school, %{})

    render(conn, "show.html",
      changeset: changeset,
      hide_school_info: true,
      school: school,
      tab: :school
    )
  end

  def update(conn, %{"data" => school_params, "redirect_tab" => redirect_tab}) do
    case Accounts.admin_update_school(conn.assigns.school, school_params) do
      {:ok, school} ->
        {_school, tab} = ProgressSchoolOnboarding.run(school, %{redirect_tab: redirect_tab})

        conn
        |> put_flash(:success, "Successfully updated settings.")
        |> redirect(to: Routes.settings_path(conn, :show, tab: tab))

      {:error, changeset} ->
        tab =
          case redirect_tab do
            "school" -> :school
            "contact" -> :contact
            "billing" -> :billing
            "profile" -> :profile
          end

        render(conn, "show.html",
          changeset: changeset,
          hide_school_info: true,
          school: conn.assigns.school,
          tab: tab
        )
    end
  end

  def get_school(%{params: %{"id" => id}} = conn, _) do
    if Accounts.is_superadmin?(conn.assigns.current_user) do
      if school = Accounts.get_school(id) |> preload([:stripe_account, :school_onboarding]) do
        conn
        |> assign(:school, school)
      else
        conn
        |> put_flash(:warning, "Unknown school.")
        |> redirect(to: "/admin/schools")
        |> halt()
      end
    else
      conn
      |> redirect(to: "/admin/settings")
      |> halt()
    end
  end

  def get_school(%{assigns: %{current_user: %{school: school}}} = conn, _) do
    conn
    |> assign(:school, preload(school, [:stripe_account, :school_onboarding]))
  end

  defp authorize_admin(conn, _) do
    if conn.query_params["tab"] in ~w(billing payment) do
      redirect_unless_user_can?(conn, [Permission.new(:invoice_custom_line_items, :modify, :all)])
    else
      conn
    end
  end

  defp redirect_back_to_path(conn) do
    conn.request_path <> "?" <> conn.query_string
  end
end

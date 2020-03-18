defmodule FlightWeb.Admin.SettingsController do
  use FlightWeb, :controller
  import Flight.Repo

  alias Flight.{
    Accounts,
    Auth.Permission,
    Billing.InvoiceCustomLineItem,
    SchoolScope
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
    custom_line_items =
      InvoiceCustomLineItem
      |> SchoolScope.school_scope(school)
      |> all
      |> Enum.map(fn custom_line_item ->
        %{
          description: custom_line_item.description,
          default_rate: custom_line_item.default_rate,
          id: custom_line_item.id
        }
      end)

    props = %{custom_line_items: custom_line_items, school_id: school.id}

    render(conn, "show.html",
      hide_school_info: true,
      props: props,
      school: conn.assigns.school,
      tab: :billing
    )
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
      {:ok, _school} ->
        redirect_append =
          case redirect_tab do
            "school" -> ""
            "contact" -> "?tab=contact"
          end

        conn
        |> put_flash(:success, "Successfully updated settings.")
        |> redirect(to: conn.request_path <> redirect_append)

      {:error, changeset} ->
        tab =
          case redirect_tab do
            "school" -> :school
            "contact" -> :contact
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
      if school = Accounts.get_school(id) |> preload(:stripe_account) do
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
    |> assign(:school, preload(school, :stripe_account))
  end

  defp authorize_admin(conn, _) do
    if conn.query_params["tab"] in ~w(billing payment) do
      redirect_unless_user_can?(conn, [Permission.new(:invoice_custom_line_items, :modify, :all)])
    else
      conn
    end
  end
end

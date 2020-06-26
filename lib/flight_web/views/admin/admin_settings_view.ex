defmodule FlightWeb.Admin.SettingsView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers
  import Scrivener.HTML
  import Flight.OnboardingUtil
  alias Flight.Auth.Permission

  def stripe_authorize_url() do
    Stripe.Connect.OAuth.authorize_url(%{
      redirect_uri: Application.get_env(:flight, :web_base_url) <> "/admin/stripe_connect"
    })
  end

  def stripe_activation_url(stripe_account) do
    "https://dashboard.stripe.com/account/activate?client_id=#{
      Application.get_env(:stripity_stripe, :connect_client_id)
    }&user_id=#{stripe_account.stripe_account_id}"
  end

  def can_access_billing?(conn) do
    Flight.Auth.Authorization.user_can?(
      conn.assigns.current_user,
      [Permission.new(:payment_settings, :modify, :all)]
    )
  end

  def nav_item_link(title, conn, school, current_tab, tab_name) do
    completed = onboarding_completed?(school)
    url = nav_item_url(conn, completed, tab_name)
    class = nav_item_class(tab_name, current_tab, completed)

    link(title, to: url, class: class)
  end

  def nav_item_url(conn, completed, tab_name) do
    if completed, do: "#{conn.request_path}?tab=#{tab_name}", else: "#"
  end

  def nav_item_class(tab_name, current_tab, completed) do
    tab_position = get_position(tab_name)
    current_tab_position = get_position(current_tab)
    completed_tab = !completed && current_tab_position > tab_position
    upcoming_tab = !completed && current_tab_position < tab_position

    onboarding_class = if !completed, do: "onboarding", else: nil
    upcoming_class = if upcoming_tab, do: "upcoming", else: nil
    completed_class = if completed_tab, do: "completed", else: nil
    active_class = if tab_name == current_tab, do: "active", else: nil

    ["nav-link", onboarding_class, upcoming_class, completed_class, active_class]
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.join(" ")
  end
end

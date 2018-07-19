defmodule FlightWeb.Admin.StripeController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def connect(conn, %{"code" => code}) do
    school =
      conn.assigns.current_user.school
      |> Flight.Repo.preload(:stripe_account)

    if school.stripe_account do
      raise "ruh roh"
    else
      with {:ok, response} <- Stripe.Connect.OAuth.token(code),
           {:ok, api_account} <- Stripe.Account.retrieve(response.stripe_user_id),
           {:ok, _} <- Accounts.create_stripe_account(api_account, conn) do
        conn
        |> redirect(to: "/admin/settings?tab=billing")
      else
        error ->
          raise inspect(error)

          conn
          |> redirect(to: "/admin/settings?tab=billing")
      end
    end
  end
end

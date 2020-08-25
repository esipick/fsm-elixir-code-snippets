defmodule FlightWeb.Admin.StripeController do
  use FlightWeb, :controller

  alias Flight.Accounts

  def connect(conn, %{"code" => code}) do
    school =
      conn.assigns.current_user.school
      |> Flight.Repo.preload(:stripe_account)

    # if school.stripe_account do
    #   raise "ruh roh"
    # else
      with false <- school.stripe_account != nil, 
          {:ok, response} <- Stripe.Connect.OAuth.token(code),
           {:ok, _} <-
             Accounts.fetch_and_create_stripe_account_from_account_id(
               response.stripe_user_id,
               conn
             ) do
        conn
        |> redirect(to: "/admin/settings?tab=billing")
      else
        true ->
        
          conn
          |> put_flash(:error, "Stripe Account already exists.")
          |> redirect(to: "/admin/settings?tab=billing")

        _ ->
          conn
          |> redirect(to: "/admin/settings?tab=billing")
      end
    # end
  end

  def connect(conn, _params) do      
      conn
      |> redirect(to: "/admin/settings?tab=billing")
  end
end
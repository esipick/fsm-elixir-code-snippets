defmodule FlightWeb.API.CardController do
  use FlightWeb, :controller

  alias FlightWeb.StripeHelper
  alias Flight.Accounts
  alias Flight.Auth.Permission

  plug(:get_user)
  plug(:authorize_modify)

  def create(conn, params) do
    user = conn.assigns.user

    case Flight.Billing.update_customer_card(user, params["stripe_token"]) do
      {:ok, _} -> render_success(conn)
      {:error, error} -> handle_stripe_error(conn, error)
    end
  end

  def update(conn, params) do
    case fetch_customer(conn) do
      {:ok, customer} ->
        case find_card(customer, params["id"]) do
          nil ->
            handle_card_not_found(conn)

          card ->
            payload = %{
              customer: customer.id,
              exp_month: params["exp_month"],
              exp_year: params["exp_year"]
            }

            case Stripe.Card.update(card.id, payload) do
              {:ok, _} -> render_success(conn)
              {:error, error} -> handle_stripe_error(conn, error)
            end
        end

      {:error, error} ->
        handle_stripe_error(conn, error)
    end
  end

  def delete(conn, params) do
    case fetch_customer(conn) do
      {:ok, customer} ->
        case find_card(customer, params["id"]) do
          nil ->
            handle_card_not_found(conn)

          card ->
            case Stripe.Card.delete(card.id, %{customer: customer.id}) do
              {:ok, _} -> render_success(conn)
              {:error, error} -> handle_stripe_error(conn, error)
            end
        end

      {:error, error} ->
        handle_stripe_error(conn, error)
    end
  end

  defp get_user(conn, _) do
    case Accounts.get_user(conn.params["user_id"], conn) do
      nil ->
        conn
        |> put_status(404)
        |> json(%{human_errors: %{user: "Not found."}})
        |> halt()

      user ->
        assign(conn, :user, user)
    end
  end

  defp fetch_customer(conn) do
    Stripe.Customer.retrieve(conn.assigns.user.stripe_customer_id || "")
  end

  defp find_card(customer, card_id) do
    Enum.find(customer.sources.data, fn s -> s.id == card_id end)
  end

  defp handle_stripe_error(conn, error) do
    conn
    |> put_status(400)
    |> json(%{human_errors: %{stripe_error: StripeHelper.error_message(error)}})
  end

  defp handle_card_not_found(conn) do
    conn
    |> put_status(404)
    |> json(%{human_errors: %{stripe_error: "Card does not exist or is already deleted."}})
  end

  defp render_success(conn) do
    conn
    |> put_status(200)
    |> json(%{result: "success"})
  end

  defp authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:users, :modify, {:personal, conn.assigns.user}),
      Permission.new(:users, :modify, :all)
    ])
  end
end

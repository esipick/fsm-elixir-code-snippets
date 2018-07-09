defmodule FlightWeb.API.PushTokenController do
  use FlightWeb, :controller

  plug(:authorize_modify when action in [:create])

  alias Flight.Auth.Permission

  def create(conn, %{"data" => token_params} = params) do
    case Flight.Notifications.update_push_token(token_params, params["user_id"]) do
      {:ok, _} ->
        resp(conn, 204, "")

      {:error, changeset} ->
        conn
        |> put_status(400)
        |> json(FlightWeb.ViewHelpers.human_error_messages(changeset))
    end
  end

  def authorize_modify(conn, _) do
    halt_unless_user_can?(conn, [
      Permission.new(:push_token, :modify, {:personal, conn.params["user_id"]})
    ])
  end
end

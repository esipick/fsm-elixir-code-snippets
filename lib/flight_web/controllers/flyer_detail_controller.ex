# defmodule FlightWeb.FlyerDetailController do
#   use FlightWeb, :controller
#   import Flight.Auth.Authorization
#   alias Flight.Auth.Permission
#
#   plug(FlightWeb.AuthenticateApiUser)
#   plug(:get_user)
#   plug(:get_flyer_details)
#   plug(:auth_update when action in [:update])
#   plug(:auth_show when action in [:show])
#
#   def show(conn, _params) do
#     render(conn, "show.json", flyer_details: conn.assigns.current_flyer_details)
#   end
#
#   def update(conn, params) do
#     with {:ok, flyer_details} <-
#            Flight.Accounts.set_flyer_details_for_user(params["data"], conn.assigns.user) do
#       render(conn, "show.json", flyer_details: flyer_details)
#     end
#   end
#
#   # Helpers
#
#   defp get_user(conn, _) do
#     assign(
#       conn,
#       :user,
#       Flight.Accounts.get_user!(conn.params["user_id"])
#     )
#   end
#
#   defp get_flyer_details(conn, _) do
#     assign(
#       conn,
#       :current_flyer_details,
#       Flight.Accounts.get_flyer_details_for_user_id(conn.params["user_id"])
#     )
#   end
#
#   # Auth
#
#   defp auth_show(conn, _) do
#     halt_unless_user_can?(conn, [
#       Permission.new(:flyer_details, :view, {:personal, conn.assigns.current_flyer_details})
#     ])
#   end
#
#   defp auth_update(conn, _) do
#     halt_unless_user_can?(conn, [
#       Permission.new(:flyer_details, :modify, {:personal, conn.assigns.current_flyer_details}),
#       Permission.new(:flyer_details, :modify, :all)
#     ])
#   end
# end

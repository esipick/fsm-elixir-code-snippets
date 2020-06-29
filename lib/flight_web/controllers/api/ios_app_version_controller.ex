defmodule FlightWeb.API.IosAppVersionController do
  use FlightWeb, :controller

  alias Flight.Repo
  alias Flight.IosAppVersion

  import Ecto.Query, warn: false

  def index(conn, _params) do
    render(conn, "index.json", latest_app_version: get_latest_ios_app_version())
  end

  defp get_latest_ios_app_version() do
    Ecto.Query.from(v in IosAppVersion, order_by: [desc: v.created_at], limit: 1)
    |> Ecto.Query.first
    |> Repo.one() || %{}
  end

end

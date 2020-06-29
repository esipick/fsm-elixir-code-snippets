defmodule FlightWeb.API.IosAppVersionView do
  use FlightWeb, :view

  def render("index.json", %{latest_app_version: version_record}) do
    %{
      data: %{
        version: Map.get(version_record, :version) || "4.0.8 (1)"
      }
    }

  end
end

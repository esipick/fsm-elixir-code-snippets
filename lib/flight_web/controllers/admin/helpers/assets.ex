defmodule FlightWeb.Admin.AssetsHelper do
  def get_redirect_param(data) do
    if data["redirect_to"] && data["redirect_to"] != "" do
      data["redirect_to"]
    else
      nil
    end
  end
end

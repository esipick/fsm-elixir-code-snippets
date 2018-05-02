defmodule FlightWeb.SidebarItem do
  defstruct [:path, :icon_class, :label, :active]

  alias FlightWeb.SidebarItem

  def build(conn) do
    [
      %SidebarItem{}
    ]
  end
end

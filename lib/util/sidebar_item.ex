defmodule FlightWeb.SidebarItem do
  defstruct [:path, :icon_class, :label, :active]

  alias FlightWeb.SidebarItem

  def build(path, query_string) do
    appended =
      if String.length(query_string) > 0 do
        "?#{query_string}"
      else
        ""
      end

    full_path = "#{path}#{appended}"

    [
      %SidebarItem{
        path: "/admin/dashboard",
        label: "Dashboard",
        icon_class: "design_app",
        active: false
      },
      %SidebarItem{
        path: "/admin/schools",
        label: "Schools",
        icon_class: "education_hat",
        active: false
      },
      %SidebarItem{
        path: "/admin/users?role=instructor",
        label: "Instructors",
        icon_class: "users_single-02",
        active: false
      },
      %SidebarItem{
        path: "/admin/users?role=student",
        label: "Students",
        icon_class: "education_hat",
        active: false
      },
      %SidebarItem{
        path: "/admin/users?role=renter",
        label: "Renters",
        icon_class: "business_badge",
        active: false
      },
      %SidebarItem{
        path: "/admin/aircrafts",
        label: "Aircraft",
        icon_class: "objects_spaceship",
        active: false
      },
      %SidebarItem{
        path: "/admin/users?role=admin",
        label: "Admins",
        icon_class: "business_briefcase-24",
        active: false
      },
      %SidebarItem{
        path: "/admin/settings",
        label: "Settings",
        icon_class: "loader_gear",
        active: false
      }
    ]
    |> Enum.map(fn item ->
      if item.path == full_path do
        %{item | active: true}
      else
        %{item | active: false}
      end
    end)
  end
end

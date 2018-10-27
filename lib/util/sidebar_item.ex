defmodule FlightWeb.SidebarItem do
  defstruct [:path, :icon_class, :label, :active]

  alias FlightWeb.SidebarItem

  def build(path, query_string, user) do
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
      if Flight.Accounts.is_superadmin?(user) do
        %SidebarItem{
          path: "/admin/schools",
          label: "Schools",
          icon_class: "education_hat",
          active: false
        }
      else
        nil
      end,
      %SidebarItem{
        path: "/admin/schedule",
        label: "Schedule",
        icon_class: "ui-1_calendar-60",
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
        icon_class: "objects_key-25",
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
        icon_class: "business_badge",
        active: false
      },
      %SidebarItem{
        path: "/admin/reports",
        label: "Reports",
        icon_class: "files_single-copy-04",
        active: false
      },
      # %SidebarItem{
      #   path: "/admin/courses",
      #   label: "Course Settings",
      #   icon_class: "education_agenda-bookmark",
      #   active: false
      # },
      %SidebarItem{
        path: "/admin/settings",
        label: "School Settings",
        icon_class: "loader_gear",
        active: false
      },
      %SidebarItem{
        path: "/admin/logout",
        label: "Log out",
        icon_class: "media-1_button-power",
        active: false
      }
    ]
    |> Enum.filter(& &1)
    |> Enum.map(fn item ->
      if String.starts_with?(full_path, item.path) do
        %{item | active: true}
      else
        %{item | active: false}
      end
    end)
  end
end

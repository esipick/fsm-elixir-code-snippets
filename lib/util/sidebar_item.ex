defmodule FlightWeb.SidebarItem do
  defstruct [:path, :icon_class, :label, :active, :prefix]

  alias FlightWeb.SidebarItem
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  def admin_sidebar(user) do
    [
      %SidebarItem{
        path: "/admin/dashboard",
        label: "Dashboard",
        icon_class: "design_app",
        active: false
      },
      %SidebarItem{
        path: "/billing/invoices",
        label: "Billing",
        icon_class: "business_money-coins",
        active: false,
        prefix: "/billing"
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
        path: "/admin/communication/new",
        label: "Communication",
        icon_class: "design_app",
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
        path: "/admin/users?role=dispatcher",
        label: "Dispatchers",
        icon_class: "tech_headphones",
        active: false
      },
      %SidebarItem{
        path: "/admin/aircrafts",
        label: "Aircraft",
        icon_class: "objects_spaceship",
        active: false
      },
      if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
        %SidebarItem{
          path: "/admin/users?role=admin",
          label: "Admins",
          icon_class: "business_badge",
          active: false
        }
      else
        nil
      end,
      %SidebarItem{
        path: "/admin/reports",
        label: "Reports",
        icon_class: "files_single-copy-04",
        active: false
      },
      # %SidebarItem{
      #   path: "/admin/courses",
      #   label: "Courses",
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
        path: "/logout",
        label: "Log out",
        icon_class: "media-1_button-power",
        active: false
      }
    ]
  end

  def instructor_sidebar do
    [
      %SidebarItem{
        path: "/billing/invoices",
        label: "Billing",
        icon_class: "business_money-coins",
        active: false,
        prefix: "/billing"
      },
      %SidebarItem{
        path: "/instructor/schedule",
        label: "Schedule",
        icon_class: "ui-1_calendar-60",
        active: false
      },
      %SidebarItem{
        path: "/logout",
        label: "Log out",
        icon_class: "media-1_button-power",
        active: false
      }
    ]
  end

  def student_sidebar do
    [
      %SidebarItem{
        path: "/billing/invoices",
        label: "Billing",
        icon_class: "business_money-coins",
        active: false,
        prefix: "/billing"
      },
      %SidebarItem{
        path: "/student/schedule",
        label: "Schedule",
        icon_class: "ui-1_calendar-60",
        active: false
      },
      %SidebarItem{
        path: "/logout",
        label: "Log out",
        icon_class: "media-1_button-power",
        active: false
      }
    ]
  end

  def build(path, query_string, user) do
    appended =
      if String.length(query_string) > 0 do
        "?#{query_string}"
      else
        ""
      end

    full_path = "#{path}#{appended}"

    items =
      case FlightWeb.RoleUtil.access_level(user) do
        "admin" -> admin_sidebar(user)
        "instructor" -> instructor_sidebar()
        "student" -> student_sidebar()
      end

    items
    |> Enum.filter(& &1)
    |> Enum.map(fn item ->
      cond do
        String.starts_with?(full_path, item.path) ->
          %{item | active: true}
        String.starts_with?(full_path, item.prefix || "unset") ->
          %{item | active: true}
        true ->
          %{item | active: false}
      end
    end)
  end
end

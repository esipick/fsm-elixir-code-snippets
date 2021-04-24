defmodule Flight.UserRolesUtils do
    alias FlightWeb.Admin.InvitationController
    alias Flight.Accounts

    def process(conn, from_contacts, %{"role" => "user" = role_slug, "tab" => "invitation"}) do
        invitations = Accounts.visible_invitations_with_role(role_slug, conn)
        available_user_roles = Accounts.get_user_roles(conn)
    
        { "users.html",
          [invitations: invitations,
          from_contacts: from_contacts,
          changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
          request_path: invite_request_path(conn),
          role: %{slug: "user"},
          available_user_roles: available_user_roles]}
    end

    def process(conn, from_contacts, %{"role" => role_slug, "tab" => "invitation"}) do
        invitations = Accounts.visible_invitations_with_role(role_slug, conn)

        {"index.html",
        [invitations: invitations,
        from_contacts: from_contacts,
        changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
        request_path: invite_request_path(conn),
        role: Accounts.role_for_slug(role_slug)]}
    end

    def process(conn, from_contacts, %{"role" => "user" = role, "tab" => "archived"} = params) do
        role_slug = %{slug: role}
        search_term = Map.get(params, "search", "")
        from_date = Map.get(params, "from_date", "")
        to_date = Map.get(params, "to_date", "")
        page_params = FlightWeb.Pagination.params(params)

        data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, from_date, to_date, :archived)

        message = ""#params["search"] && set_message(params["search"])

        {"users.html", [data: data, message: message, from_contacts: from_contacts, tab: :archived]}
    end

    def process(conn, from_contacts, %{"role" => role_slug, "tab" => "archived"} = params) do
        search_term = Map.get(params, "search", "")
        from_date = Map.get(params, "from_date", "")
        to_date = Map.get(params, "to_date", "")
        page_params = FlightWeb.Pagination.params(params)

        data =
        FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, from_date, to_date, :archived)

        message = ""#params["search"] && set_message(params["search"])

        {"index.html", [data: data, message: message, from_contacts: from_contacts, tab: :archived]}
    end

    def process(conn, from_contacts,  %{"role" => "user" = role} = params) do
        role_slug = %{slug: role}
        search_term = Map.get(params, "search", "")
        from_date = Map.get(params, "from_date", "")
        to_date = Map.get(params, "to_date", "")
        page_params = FlightWeb.Pagination.params(params)
        data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, from_date, to_date, nil)
        message = ""#params["search"] && set_message(params["search"])
        available_user_roles = Accounts.get_user_roles(conn)

        {"users.html", [ data: data,
            message: message,
            from_contacts: from_contacts,
            tab: :main,
            changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
            request_path: InvitationController.invite_request_path(conn),
            available_user_roles: available_user_roles]}
    end

    def process(conn, from_contacts, %{"role" => role_slug} = params) do
        search_term = Map.get(params, "search", "")
        from_date = Map.get(params, "from_date", "")
        to_date = Map.get(params, "to_date", "")
        page_params = FlightWeb.Pagination.params(params)
        data = FlightWeb.Admin.UserListData.build(conn, role_slug, page_params, search_term, from_date, to_date, nil)
        message = ""#params["search"] && set_message(params["search"])
    
        {"index.html",
          [data: data,
          from_contacts: from_contacts,
          message: message,
          tab: :main,
          changeset: Accounts.Invitation.create_changeset(%Accounts.Invitation{}, %{}),
          request_path: InvitationController.invite_request_path(conn),
          role: Accounts.role_for_slug(role_slug)]}
    end

    defp set_message(search_param) do
        if String.trim(search_param) == "" do
          "Please fill out search field"
        end
    end

    def invite_request_path(%{assigns: %{current_user: user}} = conn, path \\ "/admin/invitations") do
        case Flight.Accounts.is_superadmin?(user) do
          true -> "#{path}?school_id=#{Flight.SchoolScope.school_id(conn)}"
          false -> path
        end
    end
end
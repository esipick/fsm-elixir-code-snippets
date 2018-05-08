defmodule FlightWeb.Admin.InvitationControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Accounts

  describe "GET /admin/invitations" do
    test "renders for all roles", %{conn: conn} do
      for role_slug <- Accounts.Role.available_role_slugs() do
        role_fixture(%{slug: role_slug})
        invitation = invitation_fixture(%{}, Accounts.role_for_slug(role_slug))

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/invitations?role=#{role_slug}")
          |> html_response(200)

        assert content =~ invitation.first_name
      end
    end
  end

  describe "POST /admin/invitations" do
    test "creates invitation", %{conn: conn} do
      payload = %{
        data: %{
          first_name: "John",
          last_name: "Sullivan",
          email: "jonesy@hello.com",
          role_id: Accounts.Role.instructor().id
        }
      }

      conn
      |> web_auth_admin()
      |> post("/admin/invitations", payload)
      |> response_redirected_to("/admin/invitations?role=instructor")

      invitation = Accounts.get_invitation_for_email("jonesy@hello.com")
      assert invitation
    end
  end
end

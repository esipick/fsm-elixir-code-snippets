defmodule FlightWeb.Admin.InvitationControllerTest do
  use FlightWeb.ConnCase, async: false
  use Bamboo.Test, shared: true

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

    test "doesn't render accepted invitations", %{conn: conn} do
      role_slug = "admin"
      role_fixture(%{slug: role_slug})

      invitation = invitation_fixture(%{}, Accounts.role_for_slug(role_slug))
      Accounts.accept_invitation(invitation)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/invitations?role=#{role_slug}")
        |> html_response(200)

      refute content =~ invitation.email
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

      assert_delivered_email(Flight.Email.invitation_email(invitation))
      assert invitation
    end
  end

  describe "POST /admin/invitations/:id/resend" do
    test "works", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.admin())

      conn
      |> web_auth_admin()
      |> post("/admin/invitations/#{invitation.id}/resend")
      |> response_redirected_to("/admin/invitations?role=admin")

      assert_delivered_email(Flight.Email.invitation_email(invitation))
    end
  end
end

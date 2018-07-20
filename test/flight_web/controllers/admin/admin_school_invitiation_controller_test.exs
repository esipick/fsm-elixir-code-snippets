defmodule FlightWeb.Admin.SchoolInvitationControllerTest do
  use FlightWeb.ConnCase, async: false
  use Bamboo.Test, shared: true

  alias Flight.Accounts

  describe "GET /admin/school_invitations" do
    test "renders for all roles", %{conn: conn} do
      invitation = school_invitation_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/school_invitations")
        |> html_response(200)

      assert content =~ invitation.email
    end

    test "doesn't render accepted invitations", %{conn: conn} do
      invitation = school_invitation_fixture(%{accepted_at: NaiveDateTime.utc_now()})

      Accounts.accept_school_invitation(invitation)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/school_invitations")
        |> html_response(200)

      refute content =~ invitation.email
    end
  end

  describe "POST /admin/invitations" do
    test "creates invitation", %{conn: conn} do
      payload = %{
        data: %{
          email: "jonesy@hello.com",
          first_name: "Eh",
          last_name: "TooBrute"
        }
      }

      admin = admin_fixture()

      conn =
        conn
        |> web_auth(admin)
        |> post("/admin/school_invitations", payload)

      assert redirected_to(conn) == "/admin/school_invitations"

      assert invitation = Accounts.get_school_invitation_for_email("jonesy@hello.com")

      assert_delivered_email(Flight.Email.school_invitation_email(invitation))
    end
  end

  describe "POST /admin/invitations/:id/resend" do
    test "works", %{conn: conn} do
      invitation = school_invitation_fixture()

      conn
      |> web_auth_admin()
      |> post("/admin/school_invitations/#{invitation.id}/resend")
      |> response_redirected_to("/admin/school_invitations")

      assert_delivered_email(Flight.Email.school_invitation_email(invitation))
    end
  end
end

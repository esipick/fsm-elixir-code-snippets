defmodule FlightWeb.SchoolInvitationControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Accounts

  describe "GET /school_invitations/:token" do
    test "renders", %{conn: conn} do
      invitation = school_invitation_fixture()

      result =
        conn
        |> get("/school_invitations/#{invitation.token}")
        |> html_response(200)

      assert result =~ invitation.first_name
      assert result =~ invitation.last_name
      assert result =~ invitation.email
    end

    test "redirects to settings page if already accepted", %{conn: conn} do
      invitation = school_invitation_fixture()
      {:ok, _} = Accounts.accept_school_invitation(invitation)

      conn
      |> get("/school_invitations/#{invitation.token}")
      |> response_redirected_to("/admin/settings")
    end
  end

  describe "POST /school_invitations/:token" do
    @tag :integration
    test "creates school", %{conn: conn} do
      invitation = school_invitation_fixture()

      assert !invitation.accepted_at

      payload = %{
        user: %{
          first_name: "Justin",
          last_name: "Allison",
          email: "food@bards.com",
          phone_number: "801-555-5555",
          password: "justin time",
          school_name: "John Hopkins"
        }
      }

      conn =
        conn
        |> post("/school_invitations/#{invitation.token}", payload)

      assert redirected_to(conn) == "/admin/settings"

      assert school = Flight.Repo.get_by(Accounts.School, name: "John Hopkins")

      assert user = Accounts.get_user_by_email("food@bards.com", school)

      assert user.phone_number == "801-555-5555"

      invitation = Accounts.get_school_invitation(invitation.id)

      assert invitation.accepted_at

      assert Accounts.has_role?(user, "admin")

      assert {:ok, _} = Accounts.check_password(user, "justin time")
    end
  end
end

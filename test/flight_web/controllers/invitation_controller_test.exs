defmodule FlightWeb.InvitationControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Accounts

  describe "GET /invitations/:token" do
    test "renders", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.student())

      result =
        conn
        |> get("/invitations/#{invitation.token}")
        |> html_response(200)

      assert result =~ invitation.first_name
      assert result =~ invitation.last_name
      assert result =~ invitation.email
      assert result =~ "Student Registration"
    end

    test "renders correct title", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.dispatcher())

      result =
        conn
        |> get("/invitations/#{invitation.token}")
        |> html_response(200)

      assert result =~ invitation.first_name
      assert result =~ invitation.last_name
      assert result =~ invitation.email
      assert result =~ "Dispatcher Registration"
    end

    test "redirects to success page if already accepted", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.student())
      {:ok, _} = Accounts.accept_invitation(invitation)

      conn
      |> get("/invitations/#{invitation.token}")
      |> response_redirected_to("/invitations/#{invitation.token}/success")
    end
  end

  describe "POST /invitations/:token" do
    @tag :integration
    test "creates student", %{conn: conn} do
      school = school_fixture() |> real_stripe_account()
      invitation = invitation_fixture(%{}, Accounts.Role.student(), school)

      assert !invitation.accepted_at

      payload = %{
        user: %{
          first_name: "Justin",
          last_name: "Allison",
          email: "food@bards.com",
          phone_number: "801-555-5555",
          password: "justin time"
        },
        stripe_token: "tok_visa"
      }

      conn
      |> post("/invitations/#{invitation.token}", payload)
      |> response_redirected_to("/invitations/#{invitation.token}/success")

      user = Accounts.get_user_by_email("food@bards.com")

      assert user.phone_number == "801-555-5555"

      invitation = Accounts.get_invitation(invitation.id, invitation)

      assert invitation.accepted_at

      assert Accounts.has_role?(user, "student")

      assert user
      assert {:ok, _} = Accounts.check_password(user, "justin time")
    end

    @tag :integration
    test "creates instructor", %{conn: conn} do
      school = school_fixture() |> real_stripe_account()
      invitation = invitation_fixture(%{}, Accounts.Role.instructor(), school)

      assert !invitation.accepted_at

      payload = %{
        user: %{
          first_name: "Justin",
          last_name: "Allison",
          email: "food@bards.com",
          phone_number: "801-555-5555",
          password: "justin time"
        }
      }

      conn
      |> post("/invitations/#{invitation.token}", payload)
      |> response_redirected_to("/invitations/#{invitation.token}/success")

      user = Accounts.get_user_by_email("food@bards.com")

      assert user.phone_number == "801-555-5555"

      invitation = Accounts.get_invitation(invitation.id, invitation)

      assert invitation.accepted_at

      assert Accounts.has_role?(user, "instructor")

      assert user
      assert {:ok, _} = Accounts.check_password(user, "justin time")
    end
  end

  describe "GET /invitations/:token/success" do
    test "renders", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.student())
      {:ok, _} = Accounts.accept_invitation(invitation)

      conn
      |> get("/invitations/#{invitation.token}/success")
      |> html_response(200)
    end

    test "redirects to accept page if not accepted", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.student())

      conn
      |> get("/invitations/#{invitation.token}/success")
      |> response_redirected_to("/invitations/#{invitation.token}")
    end
  end
end

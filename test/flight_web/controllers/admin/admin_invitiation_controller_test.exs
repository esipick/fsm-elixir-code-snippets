defmodule FlightWeb.Admin.InvitationControllerTest do
  use FlightWeb.ConnCase, async: false
  use Bamboo.Test, shared: true

  alias Flight.Accounts

  describe "GET /admin/invitations" do
    test "renders for all roles in combined user roles", %{conn: conn} do
      for role_slug <- Accounts.Role.available_role_slugs() do
        role_fixture(%{slug: role_slug})
        invitation = invitation_fixture(%{}, Accounts.role_for_slug(role_slug))

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/invitations?role=user")
          |> html_response(200)

        assert content =~ invitation.first_name
      end
    end
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

    test "doesn't render accepted invitations in combined user roles", %{conn: conn} do
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

    test "doesn't render accepted invitations in all user role invitations", %{conn: conn} do
      role_slug = "admin"
      role_fixture(%{slug: role_slug})

      invitation = invitation_fixture(%{}, Accounts.role_for_slug(role_slug))
      Accounts.accept_invitation(invitation)

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/invitations?role=user")
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

      school = school_fixture()
      stripe_account_fixture(%{}, school)
      admin = admin_fixture(%{}, school)

      conn
      |> web_auth(admin)
      |> post("/admin/invitations", payload)
      |> response_redirected_to("/admin/invitations?role=user")

      invitation = Accounts.get_invitation_for_email("jonesy@hello.com", admin)

      assert_delivered_email(Flight.Email.invitation_email(invitation))
      assert invitation
    end

    @tag :integration
    test "show error if user already registered", %{conn: conn} do
      invitation = invitation_fixture(%{email: "onesy@hello.com"}, Accounts.Role.instructor())
      instructor_fixture(%{email: "onesy@hello.com"})
      Accounts.accept_invitation(invitation)

      payload = %{
        data: %{
          first_name: "John",
          last_name: "Sullivan",
          email: "onesy@hello.com",
          role_id: Accounts.Role.instructor().id
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/invitations", payload)
        |> response_redirected_to("/admin/users?role=user")

      assert get_flash(conn, :error) =~ "Email already exists."
    end

    @tag :integration
    test "show error if user archived", %{conn: conn} do
      invitation = invitation_fixture(%{email: "onesy@hello.com"}, Accounts.Role.student())
      Accounts.accept_invitation(invitation)
      student = student_fixture(%{email: "onesy@hello.com"})
      Accounts.archive_user(student)

      payload = %{
        data: %{
          first_name: "John",
          last_name: "Sullivan",
          email: "onesy@hello.com",
          role_id: Accounts.Role.student().id
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/invitations", payload)
        |> response_redirected_to("/admin/users?role=user&tab=archived")

      assert get_flash(conn, :error) =~
               "Student already removed with this email address. You may reinstate this account using \"Restore\" button below"
    end

    @tag :integration
    test "show error if invitation exist", %{conn: conn} do
      invitation_fixture(%{email: "onesy@hello.com"}, Accounts.Role.student())

      payload = %{
        data: %{
          first_name: "John",
          last_name: "Sullivan",
          email: "onesy@hello.com",
          role_id: Accounts.Role.student().id
        }
      }

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/invitations", payload)
        |> response_redirected_to("/admin/invitations?role=user")

      assert get_flash(conn, :error) =~
               "Student already invited at this email address. Please wait for invitation acceptance or resend invitation"
    end

    @tag :wip
    test "fails to create invitation due to no Stripe account", %{conn: conn} do
      payload = %{
        data: %{
          first_name: "John",
          last_name: "Sullivan",
          email: "jonesy@hello.com",
          role_id: Accounts.Role.instructor().id
        }
      }

      # Admin's school has no stripe account by default
      admin = admin_fixture()

      refute Flight.Repo.preload(admin.school, :stripe_account).stripe_account

      response =
        conn
        |> web_auth(admin)
        |> post("/admin/invitations", payload)
        |> html_response(200)

      refute Accounts.get_invitation_for_email("jonesy@hello.com", admin)

      assert response =~ "Stripe"
    end
  end

  @tag :integration
  describe "POST /admin/invitations/:id/resend" do
    test "works", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.admin())

      conn
      |> web_auth_admin()
      |> post("/admin/invitations/#{invitation.id}/resend")
      |> response_redirected_to("/admin/invitations?role=user")

      assert_delivered_email(Flight.Email.invitation_email(invitation))
    end

    test "show error if user already registered", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.admin())

      Accounts.accept_invitation(invitation)

      conn =
        conn
        |> web_auth_admin()
        |> post("/admin/invitations/#{invitation.id}/resend")

      assert get_flash(conn, :error) =~ "Admin already registered."
    end
  end

  @tag :integration
  describe "DELETE /admin/invitations/:id" do
    test "deletes invitation", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.admin())

      conn =
        conn
        |> web_auth_admin()
        |> delete("/admin/invitations/#{invitation.id}")

      refute Accounts.get_invitation(invitation.id, invitation.school)

      assert redirected_to(conn) == "/admin/invitations?role=user"
    end

    test "show error if user already registered", %{conn: conn} do
      invitation = invitation_fixture(%{}, Accounts.Role.admin())

      Accounts.accept_invitation(invitation)

      conn =
        conn
        |> web_auth_admin()
        |> delete("/admin/invitations/#{invitation.id}")

      assert get_flash(conn, :error) =~ "Admin already registered."
    end
  end
end

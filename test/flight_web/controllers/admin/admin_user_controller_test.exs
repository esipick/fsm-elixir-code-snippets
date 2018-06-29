defmodule FlightWeb.Admin.UserControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Accounts

  describe "GET /admin/users" do
    test "renders for all roles", %{conn: conn} do
      for role_slug <- Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(role_slug)

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/users?role=#{role_slug}")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end
  end

  describe "GET /admin/users/:id" do
    test "all roles" do
      for slug <- Flight.Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          build_conn()
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end

    test "all roles billing" do
      for slug <- Flight.Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          build_conn()
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}?tab=billing")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end

    test "all roles schedule" do
      for slug <- Flight.Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          build_conn()
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}?tab=scheduling")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    test "all roles" do
      for slug <- Flight.Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          build_conn()
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}/edit")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end
  end

  describe "PUT /admin/users/:id" do
    test "updates roles", %{conn: conn} do
      user = user_fixture() |> assign_role("admin")
      role_fixture(%{slug: "instructor"})
      role_fixture(%{slug: "student"})

      payload = %{
        user: %{},
        role_slugs: %{"instructor" => "on", "student" => "on"}
      }

      conn
      |> web_auth_admin()
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id)

      assert Accounts.has_role?(user, "instructor")
      assert Accounts.has_role?(user, "student")
      refute Accounts.has_role?(user, "admin")
    end

    test "updates certificates", %{conn: conn} do
      user = user_fixture() |> assign_role("admin")
      flyer_certificate_fixture(%{slug: "mei"})
      flyer_certificate_fixture(%{slug: "cfi"})
      flyer_certificate_fixture(%{slug: "cfii"})

      payload = %{
        user: %{},
        role_slugs: %{"admin" => "on"},
        flyer_certificate_slugs: %{"mei" => "on", "cfi" => "on"}
      }

      conn
      |> web_auth_admin()
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      assert Accounts.has_flyer_certificate?(user, "mei")
      assert Accounts.has_flyer_certificate?(user, "cfi")
      refute Accounts.has_flyer_certificate?(user, "cfii")
    end

    test "updates fields", %{conn: conn} do
      user = user_fixture() |> assign_role("admin")

      payload = %{
        user: %{first_name: "Allison", last_name: "Duprix"},
        role_slugs: %{"admin" => "on"}
      }

      conn
      |> web_auth_admin()
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user!(user.id)
      assert user.first_name == "Allison"
      assert user.last_name == "Duprix"
    end
  end
end

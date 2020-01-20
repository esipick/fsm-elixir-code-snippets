defmodule FlightWeb.Admin.UserControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.Accounts

  describe "GET /admin/users" do
    test "render users from all schools for superadmin", %{conn: conn} do
      school = school_fixture()
      user = user_fixture(%{first_name: "one first name", last_name: "one last name"}, school)

      another_school = school_fixture(%{name: "another school"})

      another_user =
        user_fixture(
          %{first_name: "another name", last_name: "another last name"},
          another_school
        )

      conn =
        conn
        |> web_auth(superadmin_fixture(%{}, school))

      for role_slug <- Accounts.Role.available_role_slugs() do
        user =
          user
          |> assign_role(role_slug)

        another_user =
          another_user
          |> assign_role(role_slug)

        content =
          conn
          |> get("/admin/users?role=#{role_slug}")
          |> html_response(200)

        assert content =~ "<th>School</th>"
        assert content =~ user.first_name
        assert content =~ "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"

        refute content =~ another_user.first_name

        refute content =~
                 "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

        content =
          conn
          |> Plug.Test.put_req_cookie("school_id", "#{another_school.id}")
          |> get("/admin/users?role=#{role_slug}")
          |> html_response(200)

        assert content =~ another_user.first_name

        assert content =~
                 "<a href=\"/admin/schools/#{another_school.id}\">#{another_school.name}</a>"

        refute content =~ user.first_name

        refute content =~
                 "<a href=\"/admin/schools/#{school.id}\">#{school.name}</a>"
      end
    end

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

    test "renders for all roles with search", %{conn: conn} do
      for role_slug <- Accounts.Role.available_role_slugs() do
        user = user_fixture() |> assign_role(role_slug)

        another_user =
          user_fixture(%{first_name: "another name", last_name: "another last name"})
          |> assign_role(role_slug)

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/users?role=#{role_slug}&search=some")
          |> html_response(200)

        assert content =~ user.first_name
        refute content =~ another_user.first_name
      end
    end

    test "does not render admins for dispatchers", %{conn: conn} do
      admin = user_fixture() |> assign_role("admin")

      conn =
        conn
        |> web_auth_dispatcher()
        |> get("/admin/users?role=admin")

      content = conn |> html_response(302)

      assert redirected_to(conn) == "/admin/dashboard"
      refute content =~ admin.first_name
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

    test "does not render admins for dispatchers", %{conn: conn} do
      admin = user_fixture() |> assign_role("admin")

      conn =
        conn
        |> web_auth_dispatcher()
        |> get("/admin/users/#{admin.id}")

      content = conn |> html_response(302)

      assert redirected_to(conn) == "/admin/dashboard"
      refute content =~ admin.first_name
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

    test "does not render admins for dispatchers", %{conn: conn} do
      admin = user_fixture() |> assign_role("admin")

      conn =
        conn
        |> web_auth_dispatcher()
        |> get("/admin/users/#{admin.id}/edit")

      content = conn |> html_response(302)

      assert redirected_to(conn) == "/admin/dashboard"
      refute content =~ admin.first_name
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

      admin = admin_fixture()

      conn
      |> web_auth(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin)

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

      admin = admin_fixture()

      conn
      |> web_auth(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin)
      assert user.first_name == "Allison"
      assert user.last_name == "Duprix"
    end

    test "does not allow dispatchers to update admins", %{conn: conn} do
      admin = user_fixture() |> assign_role("admin")

      payload = %{
        user: %{first_name: "Allison", last_name: "Duprix"},
        role_slugs: %{"instructor" => "on"}
      }

      conn
      |> web_auth_dispatcher()
      |> put("/admin/users/#{admin.id}", payload)
      |> response_redirected_to("/admin/dashboard")

      user = Accounts.get_user(admin.id, admin)
      refute user.first_name == "Allison"
      refute user.last_name == "Duprix"
    end

    test "does not allow dispatchers to promote to admins", %{conn: conn} do
      user = user_fixture() |> assign_role("dispatcher")

      payload = %{
        user: %{first_name: "Allison", last_name: "Duprix"},
        role_slugs: %{"admin" => "on", "dispatcher" => "on"}
      }

      conn
      |> web_auth_dispatcher()
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, user)
      assert user.first_name == "Allison"
      assert user.last_name == "Duprix"

      roles = Flight.Repo.preload(user, :roles).roles

      assert ["dispatcher"] == Enum.map(roles, fn r -> r.slug end)
    end
  end

  describe "POST /admin/users/:id/add_funds" do
    test "adds funds", %{conn: conn} do
      student = student_fixture(%{balance: 100})

      admin = admin_fixture()

      conn =
        conn
        |> web_auth_admin(admin)
        |> post("/admin/users/#{student.id}/add_funds", %{"amount" => 5, "description" => "boo"})

      student = Accounts.get_user(student.id, admin)

      assert get_flash(conn, :success) =~ "Successfully"
      assert student.balance == 600
    end

    test "Displays error if result is negative balance", %{conn: conn} do
      student = student_fixture(%{balance: 100})

      admin = admin_fixture()

      conn =
        conn
        |> web_auth_admin(admin)
        |> post("/admin/users/#{student.id}/add_funds", %{"amount" => -5, "description" => "boo"})

      assert redirected_to(conn) == "/admin/users/#{student.id}?tab=billing"
      assert get_flash(conn, :error) =~ "Users cannot have a negative balance."
    end
  end
end

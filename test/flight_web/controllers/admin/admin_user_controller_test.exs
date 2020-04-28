defmodule FlightWeb.Admin.UserControllerTest do
  use FlightWeb.ConnCase, async: false

  alias Flight.{Accounts, Repo}
  alias Accounts.Role

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

      for role_slug <- Role.available_role_slugs() do
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
      for role_slug <- Role.available_role_slugs() do
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
      for role_slug <- Role.available_role_slugs() do
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

    test "renders message when press search with empty field", %{conn: conn} do
      user = user_fixture() |> assign_role("student")

      another_user =
        user_fixture(%{first_name: "another name", last_name: "another last name"})
        |> assign_role("student")

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/users?role=student&search=")
        |> html_response(200)

      assert content =~ user.first_name
      assert content =~ another_user.first_name
      assert content =~ "Please fill out search field"
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
    test "all roles", %{conn: conn} do
      for slug <- Role.available_role_slugs() do
        school = school_fixture()
        admin = admin_fixture(%{}, school)
        aircraft = aircraft_fixture(%{}, school)

        instructor =
          instructor_fixture(
            %{first_name: "main_instructor_first_name", last_name: "main_instructor_last_name"},
            school
          )

        another_instructor =
          instructor_fixture(
            %{
              first_name: "another_instructor_first_name",
              last_name: "another_instructor_last_name"
            },
            school
          )

        user =
          user_fixture(%{main_instructor_id: instructor.id}, school)
          |> assign_role(slug)

        user
        |> FlightWeb.API.UserView.show_preload()
        |> Accounts.User.api_update_changeset(
          %{},
          nil,
          [aircraft],
          [],
          [instructor, another_instructor]
        )
        |> Repo.update()

        user = user |> FlightWeb.API.UserView.show_preload(force: true)

        content =
          conn
          |> web_auth_admin(admin)
          |> get("/admin/users/#{user.id}")
          |> html_response(200)

        assert content =~ user.first_name
        assert content =~ "#{aircraft.make} #{aircraft.model} (#{aircraft.tail_number})"
        assert content =~ "#{instructor.first_name} #{instructor.last_name}"
        assert content =~ "#{another_instructor.first_name} #{another_instructor.last_name}"
      end
    end

    test "all roles billing", %{conn: conn} do
      for slug <- Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}?tab=billing")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end

    test "all roles schedule", %{conn: conn} do
      for slug <- Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        content =
          conn
          |> web_auth_admin()
          |> get("/admin/users/#{user.id}?tab=scheduling")
          |> html_response(200)

        assert content =~ user.first_name
      end
    end

    test "if there is no appointment set for a student", %{conn: conn} do
      user = student_fixture()

      content =
        conn
        |> web_auth_admin()
        |> get("/admin/users/#{user.id}?tab=appointments")
        |> html_response(200)

      assert content =~ user.first_name
      assert content =~ "No appointments"
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
    test "all roles", %{conn: conn} do
      for slug <- Role.available_role_slugs() do
        user = user_fixture() |> assign_role(slug)

        unless slug == "instructor", do: user |> assign_role("instructor")

        content =
          conn
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

    test "updates avatar", %{conn: conn} do
      role_fixture(%{slug: "instructor"})
      school = school_fixture()
      user = student_fixture(%{}, school)
      admin = admin_fixture(%{}, school)

      payload = %{user: %{avatar: upload_fixture("assets/static/images/avatar.png")}}

      conn
      |> web_auth_admin(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin)
      url = Flight.AvatarUploader.urls({user.avatar, user})[:original]
      file_name_regex = "/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89AB][0-9a-f]{3}-[0-9a-f]{12}"

      assert String.match?(
               url,
               ~r/\/uploads\/test\/user\/avatars\/original#{file_name_regex}\.png\?v=\d*/i
             )

      payload = %{user: %{delete_avatar: "1"}}

      conn
      |> web_auth_admin(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin)
      refute user.avatar
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

    test "updates aircrafts", %{conn: conn} do
      school = school_fixture()
      user = user_fixture(%{}, school) |> assign_role("admin")
      aircraft = aircraft_fixture(%{}, school)

      payload = %{
        user: %{aircrafts: ["#{aircraft.id}"]}
      }

      admin = admin_fixture(%{}, school)

      conn
      |> web_auth(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin) |> Repo.preload(:aircrafts)
      assert Accounts.has_aircraft?(user, aircraft.id)
    end

    test "updates instructors", %{conn: conn} do
      school = school_fixture()
      user = user_fixture(%{}, school) |> assign_role("admin")
      instructor = instructor_fixture(%{}, school)

      payload = %{
        user: %{instructors: ["#{instructor.id}"]}
      }

      admin = admin_fixture(%{}, school)

      conn
      |> web_auth(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin) |> Repo.preload(:instructors)
      assert Accounts.has_instructor?(user, instructor.id)
    end

    test "updates fields", %{conn: conn} do
      school = school_fixture()
      user = user_fixture(%{}, school) |> assign_role("admin")
      instructor = instructor_fixture(%{}, school)

      payload = %{
        user: %{first_name: "Allison", last_name: "Duprix", main_instructor_id: instructor.id},
        role_slugs: %{"admin" => "on"}
      }

      admin = admin_fixture(%{}, school)

      conn
      |> web_auth(admin)
      |> put("/admin/users/#{user.id}", payload)
      |> response_redirected_to("/admin/users/#{user.id}")

      user = Accounts.get_user(user.id, admin)
      assert user.first_name == "Allison"
      assert user.last_name == "Duprix"
      assert user.main_instructor_id == instructor.id
    end

    test "does not allow update fields with wrong values", %{conn: conn} do
      student = student_fixture()
      instructor_fixture(%{slug: "instructor"})

      payload = %{
        user: %{email: "All@ison", zipcode: "Duprix", flight_training_number: "Duprix"}
      }

      admin = admin_fixture()

      content =
        conn
        |> web_auth(admin)
        |> put("/admin/users/#{student.id}", payload)
        |> html_response(200)

      assert content =~ "must be in the format: 12345 or 12345-6789"
      assert content =~ "must be in the format: A1234567"
      assert content =~ "must be in a valid format"
    end

    test "show error when user already removed", %{conn: conn} do
      student = student_fixture()

      payload = %{
        user: %{email: "All@ison"}
      }

      Accounts.archive_user(student)
      admin = admin_fixture()

      conn =
        conn
        |> web_auth(admin)
        |> put("/admin/users/#{student.id}", payload)
        |> response_redirected_to("/admin/dashboard")

      conn
      |> get("/admin/dashboard")
      |> html_response(200)

      assert get_flash(conn, :error) =~ "User already removed."
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

      roles = Repo.preload(user, :roles).roles

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

  @tag :integration
  describe "GET /admin/users/:id/restore" do
    test "restore", %{conn: conn} do
      student = student_fixture(%{first_name: "Bill", last_name: "Murray"})
      Accounts.archive_user(student)

      admin = admin_fixture()

      conn =
        conn
        |> web_auth_admin(admin)
        |> get("/admin/users/#{student.id}/restore?role=student")

      assert redirected_to(conn) == "/admin/users?role=student"
      assert get_flash(conn, :success) =~ "Successfully restored Bill Murray account"
      assert student.archived == false
    end

    test "Displays error if user already restored", %{conn: conn} do
      student = student_fixture(%{first_name: "Bill", last_name: "Murray", archived: false})

      admin = admin_fixture()

      conn =
        conn
        |> web_auth_admin(admin)
        |> get("/admin/users/#{student.id}/restore?role=student")

      assert redirected_to(conn) == "/admin/dashboard"
      assert get_flash(conn, :error) =~ "Bill Murray account is already restored"
    end
  end
end

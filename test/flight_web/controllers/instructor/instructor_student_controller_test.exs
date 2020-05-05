defmodule FlightWeb.Instructor.StudentControllerTest do
  use FlightWeb.ConnCase, async: true

  alias Flight.{Accounts, Repo}
  alias Accounts.Role

  describe "GET /instructor/students" do
    test "renders students with same school", %{conn: conn} do
      student = student_fixture()

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students")
        |> html_response(200)

      assert content =~ "<b>#{student.first_name} #{student.last_name}</b>"
    end

    test "does not renders students with another school", %{conn: conn} do
      another_school = school_fixture(%{name: "another school"})
      student = student_fixture(%{}, another_school)

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students")
        |> html_response(200)

      refute content =~ "<b>#{student.first_name} #{student.last_name}</b>"
    end

    test "does not renders other roles", %{conn: conn} do
      for role_slug <- Role.available_role_slugs() do
        if role_slug != "student" do
          student_fixture()

          user =
            user_fixture(%{first_name: "FirstName", last_name: "LastName"})
            |> assign_role(role_slug)

          content =
            conn
            |> web_auth_instructor
            |> get("/instructor/students")
            |> html_response(200)

          refute content =~ "<b>#{user.first_name} #{user.last_name}</b>"
        end
      end
    end

    test "renders students with search", %{conn: conn} do
      student1 = student_fixture(%{first_name: "FirstName", last_name: "LastName"})
      student2 = student_fixture()

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students?search=#{student1.first_name}")
        |> html_response(200)

      assert content =~ "<b>#{student1.first_name} #{student1.last_name}</b>"
      refute content =~ "<b>#{student2.first_name} #{student2.last_name}</b>"
    end

    test "renders message when press search with empty field", %{conn: conn} do
      student_fixture()

      content =
        conn
        |> web_auth_instructor()
        |> get("/instructor/students?search=")
        |> html_response(200)

      assert content =~ "Please fill out search field"
    end
  end

  describe "GET /instructor/students/:id" do
    test "renders student billing tab", %{conn: conn} do
      student = student_fixture()

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{student.id}")
        |> html_response(200)

      assert content =~ "<h7>Account Balance</h7>"
    end

    test "renders student appointments tab", %{conn: conn} do
      student = student_fixture()

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{student.id}?tab=appointments")
        |> html_response(200)

      assert content =~ "<h5>No appointments</h5>"
    end

    test "redirects if not student", %{conn: conn} do
      admin = admin_fixture()

      conn =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{admin.id}")

      conn |> html_response(302)
      assert redirected_to(conn) == "/instructor/profile"
    end

    test "redirect if student archived", %{conn: conn} do
      student = student_fixture()
      Accounts.archive_user(student)

      conn =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{student.id}")

      conn |> html_response(302)
      assert redirected_to(conn) == "/instructor/profile"
    end
  end

  describe "GET /instructor/students/:id/edit" do
    test "renders student edit form", %{conn: conn} do
      student = student_fixture()

      content =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{student.id}/edit")
        |> html_response(200)

      assert content =~ "<p class=\"category\">Edit Profile</p>"
    end

    test "redirects if not student", %{conn: conn} do
      admin = admin_fixture()

      conn =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{admin.id}/edit")

      conn |> html_response(302)
      assert redirected_to(conn) == "/instructor/profile"
    end

    test "redirect if student archived", %{conn: conn} do
      student = student_fixture()
      Accounts.archive_user(student)

      conn =
        conn
        |> web_auth_instructor
        |> get("/instructor/students/#{student.id}/edit")

      conn |> html_response(302)
      assert redirected_to(conn) == "/instructor/profile"
    end
  end

  describe "PUT /instructor/students/:id" do
    test "updates student", %{conn: conn} do
      student = student_fixture() |> Repo.preload(:main_instructor)
      main_instructor = instructor_fixture()
      payload = %{user: %{first_name: "new first name", main_instructor_id: main_instructor.id}}

      assert student.first_name == "some first name"
      refute student.main_instructor

      conn =
        conn
        |> web_auth_instructor
        |> put("/instructor/students/#{student.id}", payload)

      conn
      |> html_response(302)

      assert redirected_to(conn) == "/instructor/students/#{student.id}"

      student = Accounts.get_user(student.id, student) |> Repo.preload(:main_instructor)
      assert student.first_name == "new first name"
      assert student.main_instructor_id == main_instructor.id
    end

    test "updates student aircrafts", %{conn: conn} do
      student = student_fixture() |> Repo.preload(:aircrafts)
      aircraft = aircraft_fixture()
      payload = %{user: %{aircrafts: ["#{aircraft.id}"]}}

      assert student.aircrafts == []

      conn
      |> web_auth_instructor
      |> put("/instructor/students/#{student.id}", payload)
      |> html_response(302)

      student = Accounts.get_user(student.id, student) |> Repo.preload(:aircrafts)
      assert Accounts.has_aircraft?(student, aircraft.id)
    end

    test "updates student instructors", %{conn: conn} do
      student = student_fixture() |> Repo.preload(:instructors)
      instructor = instructor_fixture()
      payload = %{user: %{instructors: ["#{instructor.id}"]}}

      assert student.instructors == []

      conn
      |> web_auth_instructor
      |> put("/instructor/students/#{student.id}", payload)
      |> html_response(302)

      student = Accounts.get_user(student.id, student) |> Repo.preload(:instructors)
      assert Accounts.has_instructor?(student, instructor.id)
    end
  end
end

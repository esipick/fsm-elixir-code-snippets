defmodule FlightWeb.API.UserControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.UserView

  @tag :integration
  describe "GET /api/users" do
    test "renders directory", %{conn: conn} do
      user1 = student_fixture()
      _ = instructor_fixture()

      json =
        conn
        |> auth(user1)
        |> get("/api/users?form=directory")
        |> json_response(200)

      users =
        Flight.Repo.preload(
          Flight.Accounts.get_directory_users_visible_to_user(user1),
          :roles
        )

      assert json ==
               render_json(
                 UserView,
                 "index.json",
                 users: users,
                 form: "directory_user.json"
               )
    end
  end

  @tag :integration
  describe "GET /api/users/:id" do
    test "renders json", %{conn: conn} do
      user =
        student_fixture()
        |> FlightWeb.API.UserView.show_preload()

      json =
        conn
        |> auth(user)
        |> get("/api/users/#{user.id}")
        |> json_response(200)

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 if student requesting other student", %{conn: conn} do
      student = student_fixture()
      other_student = student_fixture()

      conn
      |> auth(other_student)
      |> get("/api/users/#{student.id}")
      |> response(401)
    end

    test "401 if no auth", %{conn: conn} do
      conn
      |> get("/api/users/4")
      |> response(401)
    end
  end

  describe "POST /api/users" do
    @tag :integration
    test "creates user", %{conn: conn} do
      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555",
        school_id: default_school_fixture().id
      }
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> post("/api/users/", %{data: user_attrs})
        |> json_response(200)

      user =
        Flight.Repo.get!(Flight.Accounts.User, json["data"]["id"])
        |> FlightWeb.API.UserView.show_preload()

      assert user.first_name == "Alexxx"

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    @tag :integration
    test "creates user with stripe account", %{conn: conn} do
      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555",
        school_id: default_school_fixture().id
      }
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> post("/api/users/", %{data: user_attrs, stripe_token: "tok_visa"})
        |> json_response(200)

      user =
        Flight.Repo.get!(Flight.Accounts.User, json["data"]["id"])
        |> FlightWeb.API.UserView.show_preload()

      assert user.first_name == "Alexxx"

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 for unauhtorized", %{conn: conn} do
      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555",
        school_id: default_school_fixture().id
      }
      student = student_fixture()

      conn
      |> auth(student)
      |> post("/api/users/", %{data: user_attrs})
      |> response(401)
    end
  end

  @tag :integration
  describe "PUT /api/users/:id" do
    test "renders json", %{conn: conn} do
      user =
        student_fixture(%{first_name: "Justin"})
        |> Flight.Repo.preload(:flyer_certificates)

      assert user.flyer_certificates == []

      cert = flyer_certificate_fixture()

      updates = %{
        first_name: "Alex",
        flyer_certificates: [cert.slug]
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(200)

      user =
        Flight.Repo.get!(Flight.Accounts.User, user.id)
        |> FlightWeb.API.UserView.show_preload()

      assert user.first_name == "Alex"
      assert user.flyer_certificates == [cert]

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    test "401 if no auth", %{conn: conn} do
      conn
      |> put("/api/users/4")
      |> response(401)
    end

    test "401 if other user", %{conn: conn} do
      user1 = student_fixture()
      user2 = student_fixture()

      conn
      |> auth(user1)
      |> put("/api/users/#{user2.id}")
      |> response(401)
    end
  end

  @tag :integration
  describe "GET /api/users/:id/form_items" do
    test "renders", %{conn: conn} do
      user = student_fixture()

      json =
        conn
        |> auth(user)
        |> get("/api/users/#{user.id}/form_items")
        |> json_response(200)

      items =
        user
        |> Flight.Accounts.editable_fields()
        |> Enum.map(&FlightWeb.UserForm.item(user, &1))

      assert json ==
               render_json(
                 UserView,
                 "form_items.json",
                 form_items: items
               )
    end
  end

  @tag :integration
  describe "GET /api/users/autocomplete" do
    test "renders json", %{conn: conn} do
      student1 = student_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      _instructor1 = instructor_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      student_fixture()
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/users/autocomplete?name=nair")
        |> json_response(200)

      assert json == render_json(UserView, "autocomplete.json", users: [student1])
    end

    test "renders specific role json", %{conn: conn} do
      _student1 = student_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      instructor1 = instructor_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      student_fixture()
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/users/autocomplete?name=nair&role=instructor")
        |> json_response(200)

      assert json == render_json(UserView, "autocomplete.json", users: [instructor1])
    end
  end

  @tag :integration
  describe "GET /api/users/by_role" do
    test "renders specific role json", %{conn: conn} do
      _student1 = student_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      instructor1 = instructor_fixture(%{first_name: "Adrian", last_name: "Nairda"})
      student_fixture()
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/users/by_role?role=instructor")
        |> json_response(200)

      assert json == render_json(UserView, "autocomplete.json", users: [instructor1, instructor])
    end
  end
end

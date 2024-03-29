defmodule FlightWeb.API.UserControllerTest do
  use FlightWeb.ConnCase

  alias FlightWeb.API.UserView
  alias Flight.{Accounts, Accounts.User, AvatarUploader, Repo}

  @tag :integration
  describe "GET /api/users" do
    test "renders directory as superadmin", %{conn: conn} do
      school = school_fixture()
      user = student_fixture(%{}, school)
      instructor = instructor_fixture(%{}, school)
      another_school = school_fixture(%{name: "another school"})
      another_user = student_fixture(%{first_name: "another user"}, another_school)
      another_instructor = instructor_fixture(%{first_name: "another instructor"}, another_school)
      superadmin = superadmin_fixture()

      json =
        conn
        |> auth(user)
        |> get("/api/users?form=directory&school_id=#{another_school.id}")
        |> json_response(200)

      [%{"id" => id1}, %{"id" => id2}] = json["data"]
      assert Enum.sort([id1, id2]) == Enum.sort([user.id, instructor.id])

      json =
        conn
        |> auth(superadmin)
        |> get("/api/users?form=directory")
        |> json_response(200)

      [%{"id" => id}] = json["data"]
      assert id == superadmin.id

      json =
        conn
        |> auth(superadmin)
        |> get("/api/users?form=directory&school_id=#{school.id}")
        |> json_response(200)

      [%{"id" => id1}, %{"id" => id2}, %{"id" => id3}] = json["data"]
      assert Enum.sort([id1, id2, id3]) == Enum.sort([user.id, instructor.id, superadmin.id])

      json =
        conn
        |> auth(superadmin)
        |> get("/api/users?form=directory&school_id=#{another_school.id}")
        |> json_response(200)

      [%{"id" => id1}, %{"id" => id2}, %{"id" => id3}] = json["data"]

      assert Enum.sort([id1, id2, id3]) ==
               Enum.sort([another_user.id, another_instructor.id, superadmin.id])
    end

    test "renders directory", %{conn: conn} do
      user1 = student_fixture()
      _ = instructor_fixture()

      conn =
        conn
        |> auth(user1)
        |> get("/api/users?form=directory&school_id${user1.school.id}")

      json =
        conn
        |> json_response(200)

      users =
        Repo.preload(
          Flight.Accounts.get_directory_users_visible_to_user(conn),
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
      student_role = role_fixture(%{slug: "student"})
      school = school_fixture() |> real_stripe_account()
      aircraft = aircraft_fixture(%{}, school)
      instructor = instructor_fixture(%{}, school)
      another_instructor = instructor_fixture(%{}, school)

      user_attrs = %{
        avatar: avatar_base64_fixture(),
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555",
        main_instructor_id: instructor.id
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{
          data: user_attrs,
          role_id: student_role.id,
          aircrafts: [aircraft.id],
          instructors: [instructor.id, another_instructor.id]
        })
        |> json_response(200)

      user =
        Repo.get!(User, json["data"]["id"])
        |> FlightWeb.API.UserView.show_preload()

      urls = AvatarUploader.urls({user.avatar, user})
      original_url = urls[:original]
      thumb_url = urls[:thumb]
      base_path = "/uploads/test/user/avatars/"
      file_name_regex = "/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89AB][0-9a-f]{3}-[0-9a-f]{12}"

      assert String.match?(original_url, ~r/#{base_path}original#{file_name_regex}\.jpeg\?v=\d*/i)
      assert String.match?(thumb_url, ~r/#{base_path}thumb#{file_name_regex}\.png\?v=\d*/i)
      AvatarUploader.delete({user.avatar, user})

      assert user.first_name == "Alexxx"
      assert user.aircrafts == [aircraft]
      assert user.main_instructor_id == instructor.id
      assert user.main_instructor_id == user.main_instructor.id

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end

    @tag :integration
    test "can't create an user with invalid aircrafts", %{
      conn: conn
    } do
      student_role = role_fixture(%{slug: "student"})
      school = school_fixture()
      aircraft = aircraft_fixture(%{}, school)
      instructor = instructor_fixture(%{}, school)

      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      Flight.Scheduling.Aircraft.archive(aircraft)

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{
          data: user_attrs,
          role_id: student_role.id,
          aircrafts: [aircraft.id]
        })
        |> json_response(400)

      assert json == %{"human_errors" => ["Aircrafts should be active: #{aircraft.id}"]}
    end

    @tag :integration
    test "can't create an user with invalid instructors", %{
      conn: conn
    } do
      student_role = role_fixture(%{slug: "student"})
      school = school_fixture()
      instructor = instructor_fixture(%{}, school)
      another_instructor = instructor_fixture(%{}, school)

      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      Accounts.archive_user(another_instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{
          data: user_attrs,
          role_id: student_role.id,
          instructors: instructors = [another_instructor.id]
        })
        |> json_response(400)

      assert json == %{
               "human_errors" => ["Instructors should be active: #{Enum.join(instructors, ", ")}"]
             }
    end

    @tag :integration
    test "can't create an user with invalid main_instructor", %{
      conn: conn
    } do
      student_role = role_fixture(%{slug: "student"})
      school = school_fixture()
      instructor = instructor_fixture(%{}, school)
      another_instructor = instructor_fixture(%{}, school)

      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555",
        main_instructor_id: another_instructor.id
      }

      Accounts.archive_user(another_instructor)

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{
          data: user_attrs,
          role_id: student_role.id
        })
        |> json_response(400)

      assert json == %{"human_errors" => ["Main instructor should be active"]}
    end

    @tag :integration
    test "can't create an user with invalid avatar", %{conn: conn} do
      student_role = role_fixture(%{slug: "student"})

      user_attrs = %{
        avatar: "wrong base64 string",
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      school = school_fixture() |> real_stripe_account()
      instructor = instructor_fixture(%{}, school)

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{data: user_attrs, role_id: student_role.id})
        |> json_response(400)

      assert json == %{"human_errors" => ["Avatar must be valid base64 encoded binary image"]}

      user_attrs =
        user_attrs
        |> Map.put(:avatar, avatar_base64_fixture("assets/static/robots.txt"))

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{data: user_attrs, role_id: student_role.id})
        |> json_response(400)

      assert json == %{
               "human_errors" => [
                 "Avatar format must be one of .jpg .jpeg .gif .png",
                 "Avatar is invalid"
               ]
             }
    end

    @tag :integration
    test "can't create an user with same email", %{conn: conn} do
      student_role = role_fixture(%{slug: "student"})
      email = "unique@email.com"
      student_fixture(%{email: email})

      user_attrs = %{
        email: email,
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      school = school_fixture() |> real_stripe_account()
      instructor = instructor_fixture(%{}, school)

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{data: user_attrs, role_id: student_role.id})
        |> json_response(400)

      assert json == %{"human_errors" => ["Email already exist"]}
    end

    @tag :integration
    test "creates user with stripe account", %{conn: conn} do
      student_role = role_fixture(%{slug: "student"})

      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> post("/api/users", %{
          data: user_attrs,
          role_id: student_role.id,
          stripe_token: "tok_visa"
        })
        |> json_response(200)

      user =
        Repo.get!(User, json["data"]["id"])
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
      student_role = role_fixture(%{slug: "student"})

      user_attrs = %{
        email: "user-#{Flight.Random.string(20)}@email.com",
        first_name: "Alexxx",
        last_name: "Doe",
        phone_number: "801-555-5555"
      }

      student = student_fixture()

      conn
      |> auth(student)
      |> post("/api/users", %{data: user_attrs, role_id: student_role.id})
      |> response(401)
    end
  end

  describe "Check password_token" do
    test "Users with old api token must stay authorized", %{conn: conn} do
      {:ok, user} =
        student_fixture()
        |> User.__test_password_token_changeset(%{password_token: nil})
        |> Repo.update()

      assert is_nil(user.password_token)

      conn =
        conn
        |> auth(user)

      conn
      |> get("/api/users/#{user.id}")
      |> json_response(200)

      updates = %{
        password: "some password",
        new_password: "new password"
      }

      conn
      |> put("/api/users/#{user.id}/change_password", %{data: updates})
      |> json_response(200)

      user = Repo.get!(User, user.id)

      refute is_nil(user.password_token)

      conn
      |> get("/api/users/#{user.id}")
      |> response(401)
    end
  end

  describe "PUT /api/users/:user_id/change_password" do
    test "update password", %{conn: conn} do
      user = student_fixture()
      current_password = "some password"
      new_password = "new password"

      assert {:ok, _user} = Flight.Accounts.check_password(user, current_password)
      assert {:error, "invalid password"} = Flight.Accounts.check_password(user, new_password)

      conn =
        conn
        |> auth(user)

      json =
        conn
        |> put("/api/users/#{user.id}/change_password", %{data: %{new_password: new_password}})
        |> json_response(422)

      assert json == %{"human_errors" => ["Password can't be empty"]}

      json =
        conn
        |> put("/api/users/#{user.id}/change_password", %{data: %{password: current_password}})
        |> json_response(422)

      assert json == %{"human_errors" => ["New password can't be empty"]}

      json =
        conn
        |> put("/api/users/#{user.id}/change_password", %{
          data: %{password: "wrong password", new_password: new_password}
        })
        |> json_response(422)

      assert json == %{"human_errors" => ["Password is invalid"]}

      json =
        conn
        |> put("/api/users/#{user.id}/change_password", %{
          data: %{password: current_password, new_password: "new"}
        })
        |> json_response(422)

      assert json == %{"human_errors" => ["Password must be at least 6 characters"]}

      updates = %{
        password: current_password,
        new_password: new_password
      }

      json =
        conn
        |> put("/api/users/#{user.id}/change_password", %{data: updates})
        |> json_response(200)

      user =
        Repo.get!(User, json["data"]["id"])
        |> FlightWeb.API.UserView.show_preload()

      assert {:ok, _user} = Flight.Accounts.check_password(user, new_password)

      assert json ==
               render_json(
                 FlightWeb.API.UserView,
                 "show.json",
                 user: user
               )
    end
  end

  @tag :integration
  describe "PUT /api/users/:id" do
    test "renders json", %{conn: conn} do
      school = school_fixture() |> Repo.preload(:stripe_account)

      user =
        student_fixture(%{first_name: "Justin"}, school)
        |> Repo.preload([:aircrafts, :flyer_certificates, :instructors, :main_instructor])

      assert user.aircrafts == []
      assert user.flyer_certificates == []
      assert user.instructors == []
      refute user.main_instructor_id

      aircraft = aircraft_fixture(%{}, school)
      cert = flyer_certificate_fixture()
      instructor = instructor_fixture(%{}, school)
      another_instructor = instructor_fixture(%{}, school)

      updates = %{
        first_name: "Alex",
        aircrafts: [aircraft.id],
        flyer_certificates: [cert.slug],
        instructors: [another_instructor.id],
        main_instructor_id: instructor.id
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(200)

      user =
        Repo.get!(User, user.id)
        |> FlightWeb.API.UserView.show_preload()

      assert user.first_name == "Alex"
      assert user.flyer_certificates == [cert]
      assert user.main_instructor_id == instructor.id
      assert user.main_instructor_id == user.main_instructor.id

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

    @tag :integration
    test "can't update an user with invalid aircrafts", %{
      conn: conn
    } do
      school = school_fixture()
      user = student_fixture(%{}, school)
      aircraft = aircraft_fixture(%{}, school)

      Flight.Scheduling.Aircraft.archive(aircraft)

      updates = %{
        first_name: "Alex",
        aircrafts: [aircraft.id]
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(400)

      assert json == %{"human_errors" => ["Aircrafts should be active: #{aircraft.id}"]}
    end

    @tag :integration
    test "can't update an user with invalid instructors", %{
      conn: conn
    } do
      school = school_fixture()
      user = student_fixture(%{}, school)
      instructor = instructor_fixture(%{}, school)
      another_instructor = instructor_fixture(%{}, school)

      Accounts.archive_user(instructor)
      Accounts.archive_user(another_instructor)

      updates = %{
        first_name: "Alex",
        instructors: instructors = [instructor.id, another_instructor.id]
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(400)

      assert json == %{
               "human_errors" => ["Instructors should be active: #{Enum.join(instructors, ", ")}"]
             }
    end

    @tag :integration
    test "can't update an user with invalid main_instructor", %{
      conn: conn
    } do
      school = school_fixture()
      user = student_fixture(%{}, school)
      instructor = instructor_fixture(%{}, school)

      Accounts.archive_user(instructor)

      updates = %{
        first_name: "Alex",
        main_instructor_id: instructor.id
      }

      json =
        conn
        |> auth(user)
        |> put("/api/users/#{user.id}", %{data: updates})
        |> json_response(400)

      assert json == %{"human_errors" => ["Main instructor should be active"]}
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

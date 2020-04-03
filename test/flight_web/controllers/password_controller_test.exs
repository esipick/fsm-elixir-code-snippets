defmodule FlightWeb.PasswordControllerTest do
  use FlightWeb.ConnCase, async: false
  use Bamboo.Test, shared: true

  describe "GET /forgot_password" do
    test "renders", %{conn: conn} do
      conn
      |> get("/forgot_password")
      |> html_response(200)
    end
  end

  describe "POST /forgot_password" do
    test "sends email and redirects", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> post("/forgot_password", %{email: user.email})
        |> response_redirected_to("/forgot_password")

      assert password_reset = Flight.Accounts.get_password_reset(user)

      password_reset
      |> Flight.Email.reset_password_email()
      |> assert_delivered_email()

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Please check your email for password reset instructions."
    end

    test "user removed", %{conn: conn} do
      user = user_fixture()
      Flight.Accounts.archive_user(user)

      conn =
        conn
        |> post("/forgot_password", %{email: user.email})
        |> response_redirected_to("/forgot_password")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Account is suspended. Please contact your school administrator to reinstate it."
    end

    test "empty email", %{conn: conn} do
      conn =
        conn
        |> post("/forgot_password", %{email: ""})
        |> response_redirected_to("/forgot_password")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Please enter your email"
    end

    test "invalid email", %{conn: conn} do
      conn =
        conn
        |> post("/forgot_password", %{email: "invalid email"})
        |> response_redirected_to("/forgot_password")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Invalid email format"
    end

    test "unregistered email", %{conn: conn} do
      conn =
        conn
        |> post("/forgot_password", %{email: "unregistered@example.com"})
        |> response_redirected_to("/forgot_password")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "This email is not registered"
    end
  end

  describe "GET /reset_password" do
    test "renders if valid token", %{conn: conn} do
      user = user_fixture()
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn
      |> get("/reset_password", %{token: reset.token})
      |> html_response(200)
    end

    test "redirects back to forgot password with error if invalid token", %{conn: conn} do
      conn =
        conn
        |> get("/reset_password")
        |> response_redirected_to("/forgot_password")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~
               "The reset link you clicked is either expired or invalid. Please attempt to reset your password again by entering your email."
    end
  end

  describe "POST /reset_password" do
    test "resets password and renders success", %{conn: conn} do
      user = user_fixture()
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn
      |> post("/reset_password", %{
        token: reset.token,
        password: "this old thing",
        password_confirmation: "this old thing"
      })
      |> html_response(200)

      assert {:ok, _user} = Flight.Accounts.check_password(refresh(user), "this old thing")
    end

    test "try again if passwords don't match", %{conn: conn} do
      user = user_fixture()
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn =
        conn
        |> post("/reset_password", %{
          token: reset.token,
          password: "this old thing",
          password_confirmation: "this old thang"
        })
        |> response_redirected_to("/reset_password?token=#{reset.token}")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Password and confirmation didn&#39;t match. Please try again."
    end

    test "try again if passwords too short", %{conn: conn} do
      user = user_fixture()
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn =
        conn
        |> post("/reset_password", %{
          token: reset.token,
          password: "short",
          password_confirmation: "short"
        })
        |> response_redirected_to("/reset_password?token=#{reset.token}")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Password must be at least 6 characters."
    end

    test "password and confirmation didn't match", %{conn: conn} do
      user = user_fixture()
      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn =
        conn
        |> post("/reset_password", %{
          token: reset.token,
          password: "",
          password_confirmation: ""
        })
        |> response_redirected_to("/reset_password?token=#{reset.token}")

      html =
        conn
        |> get("/forgot_password")
        |> html_response(200)

      assert html =~ "Password can&#39;t be blank."
    end
  end
end

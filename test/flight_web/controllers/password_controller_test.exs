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

      assert redirected_to(conn) == "/forgot_password"

      assert password_reset = Flight.Accounts.get_password_reset(user)

      password_reset
      |> Flight.Email.reset_password_email()
      |> assert_delivered_email()
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

      assert redirected_to(conn) == "/forgot_password"
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

      assert redirected_to(conn) == "/reset_password?token=#{reset.token}"
    end

    test "try again if password is too short", %{conn: conn} do
      user = user_fixture()

      {:ok, reset} = Flight.Accounts.create_password_reset(user)

      conn =
        conn
        |> post("/reset_password", %{
          token: reset.token,
          password: "this",
          password_confirmation: "this"
        })

      assert redirected_to(conn) == "/reset_password?token=#{reset.token}"
    end
  end
end

defmodule FlightWeb.SessionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /login" do
    test "renders", %{conn: conn} do
      conn
      |> get("/login")
      |> html_response(200)
    end

    test "redirects to dashboard if logged in", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/login")
      |> response_redirected_to("/admin/dashboard")
    end
  end

  describe "GET /logout" do
    test "redirects to dashboard if logged in", %{conn: conn} do
      conn
      |> web_auth_admin()
      |> get("/logout")
      |> response_redirected_to("/login")
    end
  end

  describe "POST /login" do
    test "redirects to dashboard on success", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("admin")

      conn
      |> post("/login", %{email: "hello@bar.com", password: "hey hey you"})
      |> response_redirected_to("/admin/dashboard")
    end

    test "redirects to dashboard if dispatcher", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("dispatcher")

      conn
      |> post("/login", %{email: "hello@bar.com", password: "hey hey you"})
      |> response_redirected_to("/admin/dashboard")
    end

    test "redirects to login on failure", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})

      conn =
        conn
        |> post("/login", %{email: "hello@bar.com", password: "hey hey yous"})
        |> redirected_to_login()

      assert get_flash(conn, :error) =~ "Invalid"
    end

    test "redirects to login if empty fields", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})

      conn =
        conn
        |> post("/login", %{email: "", password: "hey hey you"})
        |> redirected_to_login()

      assert get_flash(conn, :error) =~ "Username and password can't be blank."
    end

    test "redirects to login if user is not an admin", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("renter")

      conn =
        conn
        |> post("/login", %{email: "hello@bar.com", password: "hey hey you"})
        |> redirected_to_login()

      assert get_flash(conn, :error) =~ "You are not allowed to log in"
    end

    test "redirects to dashboard if user is student", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("student")

      conn
      |> post("/login", %{email: "hello@bar.com", password: "hey hey you"})
      |> response_redirected_to("/student/profile")
    end

    test "redirects to dashboard if user is instructor", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("instructor")

      conn
      |> post("/login", %{email: "hello@bar.com", password: "hey hey you"})
      |> response_redirected_to("/instructor/profile")
    end
  end
end

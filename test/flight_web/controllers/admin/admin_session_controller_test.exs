defmodule FlightWeb.Admin.SessionControllerTest do
  use FlightWeb.ConnCase, async: true

  describe "GET /admin/login" do
    test "renders", %{conn: conn} do
      conn
      |> get("/admin/login")
      |> html_response(200)
    end
  end

  describe "POST /admin/login" do
    test "redirects to dashboard on success", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("admin")

      conn
      |> post("/admin/login", %{email: "hello@bar.com", password: "hey hey you"})
      |> response_redirected_to("/admin/dashboard")
    end

    test "redirects to login on failure", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})

      conn =
        conn
        |> post("/admin/login", %{email: "hello@bar.com", password: "hey hey yous"})
        |> redirected_to_login()

      assert get_flash(conn, :error) =~ "Invalid"
    end

    test "redirects to login if user is not an admin", %{conn: conn} do
      user_fixture(%{email: "hello@bar.com", password: "hey hey you"})
      |> assign_role("student")

      conn =
        conn
        |> post("/admin/login", %{email: "hello@bar.com", password: "hey hey you"})
        |> redirected_to_login()

      assert get_flash(conn, :error) =~ "admin"
    end
  end
end

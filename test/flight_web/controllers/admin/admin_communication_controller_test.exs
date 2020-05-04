defmodule FlightWeb.Admin.CommunicationControllerTest do
  use FlightWeb.ConnCase, async: false
  use Bamboo.Test, shared: true

  describe "POST /admin/communication" do
    @tag :integration
    test "create communication email", %{conn: conn} do
      payload = %{
        data: %{
          from: "John@mail.com",
          subject: "Subject",
          body: "Some text"
        }
      }

      school = school_fixture()
      stripe_account_fixture(%{}, school)
      admin = admin_fixture(%{}, school)
      _student = student_fixture(%{}, school)
      _instructor = instructor_fixture(%{}, school)
      users = Flight.Accounts.get_users(school)

      conn =
        conn
        |> web_auth(admin)
        |> post("/admin/communication", payload)
        |> response_redirected_to("/admin/communication/new")

      {:ok, email} = Flight.Email.admin_create_communication_email(users, payload.data)

      assert get_flash(conn, :success) =~ "Successfully sent email."
      assert_delivered_email(email)
    end

    @tag :integration
    test "show error if empty fields", %{conn: conn} do
      payload = %{
        data: %{
          from: "Johnmail.com",
          subject: "",
          body: ""
        }
      }

      school = school_fixture()
      stripe_account_fixture(%{}, school)
      admin = admin_fixture(%{}, school)
      users = Flight.Accounts.get_users(school)

      conn
      |> web_auth(admin)
      |> post("/admin/communication", payload)
      |> html_response(200)

      assert {:error, _changeset} =
               Flight.Email.admin_create_communication_email(users, payload.data)
    end
  end
end

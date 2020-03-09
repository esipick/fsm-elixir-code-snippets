defmodule FlightWeb.API.Invoices.LineItemControllerTest do
  use FlightWeb.ConnCase

  describe "POST /api/invoices" do
    test "renders unauthorized", %{conn: conn} do
      student = student_fixture()

      conn
      |> auth(student)
      |> get("/api/invoices/line_items/extra_options")
      |> json_response(401)
    end

    test "renders available items", %{conn: conn} do
      instructor = instructor_fixture()

      json =
        conn
        |> auth(instructor)
        |> get("/api/invoices/line_items/extra_options")
        |> json_response(200)

      assert json["data"] == [
               %{"default_rate" => 100, "description" => "Fuel Charge"},
               %{"default_rate" => 100, "description" => "Fuel Reimbursement"},
               %{"default_rate" => 100, "description" => "Equipment Rental"}
             ]
    end
  end
end

defmodule FlightWeb.API.Invoices.LineItemControllerTest do
  use FlightWeb.ConnCase

  describe "POST /api/invoices" do
    test "renders available items", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      invoice_custom_line_item_fixture(%{
        description: "Fuel Charge",
        school_id: instructor.school_id
      })

      invoice_custom_line_item_fixture(%{
        description: "Fuel Reimbursement",
        default_rate: 1000,
        school_id: instructor.school_id
      })

      invoice_custom_line_item_fixture(%{
        description: "Equipment Rental",
        default_rate: 10000,
        school_id: instructor.school_id
      })

      json =
        conn
        |> auth(student)
        |> get("/api/invoices/line_items/extra_options")
        |> json_response(200)

      assert json["data"] == [
               %{
                 "default_rate" => 10000,
                 "description" => "Equipment Rental",
                 "taxable" => true,
                 "deductible" => false
               },
               %{
                 "default_rate" => 1000,
                 "description" => "Fuel Reimbursement",
                 "taxable" => true,
                 "deductible" => false
               },
               %{
                 "default_rate" => 100,
                 "description" => "Fuel Charge",
                 "taxable" => true,
                 "deductible" => false
               }
             ]
    end
  end
end

defmodule Flight.Billing.CalculateInvoiceTest do
  use Flight.DataCase

  test "run/2 returns valid total values" do
    instructor = instructor_fixture()
    student = student_fixture()
    aircraft = aircraft_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}

    invoice_attrs = %{
      "line_items" => [
        %{
          "type" => "aircraft",
          "tach_start" => 4,
          "tach_end" => 5,
          "rate" => 100,
          "quantity" => 1,
          "hobbs_start" => 5,
          "hobbs_end" => 6,
          "hobbs_tach_used" => true,
          "description" => "Flight Hours",
          "aircraft_id" => aircraft.id,
          "taxable" => true,
          "amount" => 100
        },
        %{
          "type" => "instructor",
          "rate" => 200,
          "quantity" => 2,
          "description" => "Instructor Hours",
          "instructor_user_id" => instructor.id,
          "taxable" => true,
          "amount" => 400
        },
        %{
          "type" => "other",
          "rate" => 5200,
          "quantity" => 1,
          "description" => "Fuel",
          "taxable" => false,
          "amount" => 5200
        },
        %{
          "type" => "other",
          "rate" => 50,
          "quantity" => 1,
          "description" => "Discount",
          "deductible" => true,
          "taxable" => false,
          "amount" => 50
        }
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    assert attrs["total_tax"] == 50
    assert attrs["total"] == 5650
    assert attrs["total_amount_due"] == 5700
  end
end

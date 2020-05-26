defmodule Flight.Billing.CalculateInvoiceTest do
  use Flight.DataCase

  test "run/2 returns valid total values" do
    instructor = instructor_fixture()
    student = student_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}

    invoice_attrs = %{
      "line_items" => [
        aircraft_item_fixture(),
        instructor_item_fixture(%{}, instructor),
        other_item_fixture(),
        discount_item_fixture()
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    assert attrs["total_tax"] == 53
    assert attrs["total"] == 5680
    assert attrs["total_amount_due"] == 5733
  end

  test "run/2 calculates invoice without tach end" do
    instructor = instructor_fixture()
    student = student_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}

    invoice_attrs = %{
      "line_items" => [
        aircraft_item_fixture(%{"tach_end" => nil}),
        instructor_item_fixture(%{}, instructor),
        other_item_fixture(),
        discount_item_fixture()
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    assert attrs["total_tax"] == 53
    assert attrs["total"] == 5680
    assert attrs["total_amount_due"] == 5733
  end

  test "run/2 calculates invoice without hobbs end" do
    instructor = instructor_fixture()
    student = student_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}

    invoice_attrs = %{
      "line_items" => [
        aircraft_item_fixture(%{"hobbs_end" => nil, "tach_end" => nil}),
        instructor_item_fixture(%{}, instructor),
        other_item_fixture(),
        discount_item_fixture()
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    aircraft_item = Enum.find(attrs["line_items"], fn x -> x["type"] == "aircraft" end)

    assert aircraft_item["errors"][:aircraft_details] == %{
             hobbs_end: ["can't be blank"],
             tach_end: ["can't be blank"]
           }

    assert attrs["total_tax"] == 50
    assert attrs["total"] == 5650
    assert attrs["total_amount_due"] == 5700
  end

  test "run/2 returns error when time is greater than aircraft last time" do
    instructor = instructor_fixture()
    student = student_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}
    aircraft = aircraft_fixture(%{last_hobbs_time: 100, last_tach_time: 100})

    invoice_attrs = %{
      "line_items" => [
        aircraft_item_fixture(%{}, aircraft),
        instructor_item_fixture(%{}, instructor),
        other_item_fixture(),
        discount_item_fixture()
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    aircraft_item = Enum.find(attrs["line_items"], fn x -> x["type"] == "aircraft" end)

    assert aircraft_item["errors"][:aircraft_details] == %{
             hobbs_start: ["must be greater than current aircraft hobbs start (10.0)"]
           }

    assert attrs["total_tax"] == 53
    assert attrs["total"] == 5680
    assert attrs["total_amount_due"] == 5733
  end

  test "run/2 does not return error when aircraft last time validation disabled" do
    instructor = instructor_fixture()
    student = student_fixture()
    school_context = %Plug.Conn{assigns: %{current_user: instructor}}
    aircraft = aircraft_fixture(%{last_hobbs_time: 100, last_tach_time: 100})

    invoice_attrs = %{
      "ignore_last_time" => true,
      "line_items" => [
        aircraft_item_fixture(%{}, aircraft),
        instructor_item_fixture(%{}, instructor),
        other_item_fixture(),
        discount_item_fixture()
      ],
      "user_id" => student.id
    }

    {:ok, attrs} = Flight.Billing.CalculateInvoice.run(invoice_attrs, school_context)

    aircraft_item = Enum.find(attrs["line_items"], fn x -> x["type"] == "aircraft" end)

    refute aircraft_item["errors"]

    assert attrs["total_tax"] == 53
    assert attrs["total"] == 5680
    assert attrs["total_amount_due"] == 5733
  end

  defp aircraft_item_fixture(attrs \\ %{}, aircraft \\ aircraft_fixture()) do
    %{
      "type" => "aircraft",
      "tach_start" => 40,
      "tach_end" => 50,
      "rate" => 100,
      "quantity" => 1,
      "hobbs_start" => 50,
      "hobbs_end" => 60,
      "hobbs_tach_used" => true,
      "description" => "Flight Hours",
      "aircraft_id" => aircraft.id,
      "taxable" => true,
      "amount" => 100
    }
    |> Map.merge(attrs)
  end

  defp instructor_item_fixture(attrs, instructor) do
    %{
      "type" => "instructor",
      "rate" => 200,
      "quantity" => 2,
      "description" => "Instructor Hours",
      "instructor_user_id" => instructor.id,
      "taxable" => true,
      "amount" => 400
    }
    |> Map.merge(attrs)
  end

  defp discount_item_fixture(attrs \\ %{}) do
    %{
      "type" => "other",
      "rate" => 50,
      "quantity" => 1,
      "description" => "Discount",
      "deductible" => true,
      "taxable" => false,
      "amount" => 50
    }
    |> Map.merge(attrs)
  end

  defp other_item_fixture(attrs \\ %{}) do
    %{
      "type" => "other",
      "rate" => 5200,
      "quantity" => 1,
      "description" => "Fuel",
      "taxable" => false,
      "amount" => 5200
    }
    |> Map.merge(attrs)
  end
end

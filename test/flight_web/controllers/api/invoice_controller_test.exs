defmodule FlightWeb.API.InvoiceControllerTest do
  use FlightWeb.ConnCase

  import Ecto.Query

  alias FlightWeb.API.InvoiceView
  alias Flight.{Repo, Billing.Invoice, Billing.InvoiceLineItem}

  describe "POST /api/invoices" do
    test "renders invoice json errors", %{conn: conn} do
      instructor = instructor_fixture()
      invoice_params = %{}

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(422)

      invoice_error_response = %{
        "human_errors" => [
          "User can't be blank",
          "Total tax can't be blank",
          "Total amount due can't be blank",
          "Total can't be blank",
          "Tax rate can't be blank",
          "Payment option can't be blank",
          "Date can't be blank"
        ]
      }

      assert json == invoice_error_response
    end

    test "creates invoice", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "cc",
        total: 200,
        tax_rate: 0.2,
        total_tax: 40,
        total_amount_due: 240,
        line_items: [
          %{ description: "flight hours", rate: 15, quantity: 10, amount: 150 },
          %{ description: "discount", rate: -25, quantity: 1, amount: -25 },
          %{ description: "fuel reimbursement", rate: 75, quantity: 1, amount: 75 }
        ]
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(201)

      invoice =
        Repo.get_by(Invoice, user_id: student.id)
        |> Repo.preload([:user, line_items: (from i in InvoiceLineItem, order_by: i.inserted_at)])

      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end
  end
end

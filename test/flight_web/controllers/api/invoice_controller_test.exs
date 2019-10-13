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

      errors = %{
        "date" => ["can't be blank"],
        "payment_option" => ["can't be blank"],
        "tax_rate" => ["can't be blank"],
        "total" => ["can't be blank"],
        "total_amount_due" => ["can't be blank"],
        "total_tax" => ["can't be blank"],
        "user_id" => ["can't be blank"]
      }

      assert json["errors"] == errors
    end

    test "renders stripe error", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "cc",
        total: 20000,
        tax_rate: 0.2,
        total_tax: 4000,
        total_amount_due: 24000,
        line_items: [
          %{ description: "flight hours", rate: 1500, quantity: 10, amount: 15000 },
          %{ description: "discount", rate: -2500, quantity: 1, amount: -2500 },
          %{ description: "fuel reimbursement", rate: 7500, quantity: 1, amount: 7500 }
        ]
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/invoices", %{invoice: invoice_params})
        |> json_response(400)

      assert String.starts_with?(json["stripe_error"], "No such customer: cus_")
    end

    test "creates invoice when payment option is not balance or cc", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "cash",
        total: 20000,
        tax_rate: 0.2,
        total_tax: 4000,
        total_amount_due: 24000,
        line_items: [
          %{ description: "flight hours", rate: 1500, quantity: 10, amount: 15000 },
          %{ description: "discount", rate: -2500, quantity: 1, amount: -2500 },
          %{ description: "fuel reimbursement", rate: 7500, quantity: 1, amount: 7500 }
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

    test "creates invoice when payment option is balance (enough)", %{conn: conn} do
      {student, _} = student_fixture(%{balance: 30000}) |> real_stripe_customer()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "balance",
        total: 20000,
        tax_rate: 0.2,
        total_tax: 4000,
        total_amount_due: 24000,
        line_items: [
          %{ description: "flight hours", rate: 1500, quantity: 10, amount: 15000 },
          %{ description: "discount", rate: -2500, quantity: 1, amount: -2500 },
          %{ description: "fuel reimbursement", rate: 7500, quantity: 1, amount: 7500 }
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

      assert invoice.user.balance == 6000
      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    test "creates invoice when payment option is balance (not enough)", %{conn: conn} do
      {student, _} = student_fixture(%{balance: 20000}) |> real_stripe_customer()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "balance",
        total: 20000,
        tax_rate: 0.2,
        total_tax: 4000,
        total_amount_due: 24000,
        line_items: [
          %{ description: "flight hours", rate: 1500, quantity: 10, amount: 15000 },
          %{ description: "discount", rate: -2500, quantity: 1, amount: -2500 },
          %{ description: "fuel reimbursement", rate: 7500, quantity: 1, amount: 7500 }
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

      assert invoice.user.balance == 0
      assert json == render_json(InvoiceView, "show.json", invoice: invoice)
    end

    test "creates invoice when payment option is cc", %{conn: conn} do
      {student, _} = student_fixture() |> real_stripe_customer()
      instructor = instructor_fixture()

      invoice_params = %{
        user_id: student.id,
        date: ~D[2019-10-10],
        payment_option: "cc",
        total: 20000,
        tax_rate: 0.2,
        total_tax: 4000,
        total_amount_due: 24000,
        line_items: [
          %{ description: "flight hours", rate: 1500, quantity: 10, amount: 15000 },
          %{ description: "discount", rate: -2500, quantity: 1, amount: -2500 },
          %{ description: "fuel reimbursement", rate: 7500, quantity: 1, amount: 7500 }
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

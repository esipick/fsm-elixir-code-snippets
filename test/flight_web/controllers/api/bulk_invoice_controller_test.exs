defmodule FlightWeb.API.BulkInvoiceControllerTest do
  use FlightWeb.ConnCase

  alias Flight.Repo
  alias FlightWeb.API.BulkInvoiceView
  alias Flight.Billing.{BulkInvoice, Invoice}

  describe "POST /api/invoices" do
    @tag :integration
    test "renders unauthorized", %{conn: conn} do
      student = student_fixture()
      invoice_params = %{}

      conn
      |> auth(student)
      |> post("/api/bulk_invoices", %{invoice: invoice_params})
      |> json_response(401)
    end

    @tag :integration
    test "creates invoice when payment option is not balance or cc", %{conn: conn} do
      student = student_fixture()
      instructor = instructor_fixture()
      invoice1 = invoice_fixture(%{total_amount_due: 10000}, student)
      invoice2 = invoice_fixture(%{total_amount_due: 10000}, student)

      payload = %{
        payment_option: "cash",
        user_id: student.id,
        total_amount_due: 20000,
        invoice_ids: [invoice1.id, invoice2.id]
      }

      json =
        conn
        |> auth(instructor)
        |> post("/api/bulk_invoices", %{bulk_invoice: payload})
        |> json_response(201)

      bulk_invoice = Repo.get(BulkInvoice, json["data"]["id"]) |> Repo.preload(:bulk_transaction)

      transaction = bulk_invoice.bulk_transaction

      assert is_nil(transaction.stripe_charge_id)
      assert not is_nil(transaction.completed_at)

      assert transaction.state == "completed"
      assert transaction.total == 20000
      assert transaction.type == "debit"
      assert transaction.payment_option == :cash
      assert transaction.paid_by_cash == 20000
      assert transaction.bulk_invoice_id == bulk_invoice.id

      assert json == render_json(BulkInvoiceView, "show.json", bulk_invoice: bulk_invoice)

      invoice1 = Repo.get(Invoice, invoice1.id) |> Repo.preload(:bulk_transaction)
      invoice2 = Repo.get(Invoice, invoice2.id) |> Repo.preload(:bulk_transaction)

      assert invoice1.status == :paid
      assert invoice1.bulk_invoice_id == bulk_invoice.id
      assert invoice1.bulk_transaction.id == transaction.id

      assert invoice2.status == :paid
      assert invoice2.bulk_invoice_id == bulk_invoice.id
      assert invoice2.bulk_transaction.id == transaction.id
    end
  end
end

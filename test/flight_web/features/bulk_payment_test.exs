defmodule FlightWeb.Features.BulkPaymentTest do
  use FlightWeb.FeatureCase, async: false

  def pay_ivoice(session), do: session |> click(css("#pay"))

  @tag :integration
  test "admin can make bulk payment", %{session: session} do
    student = student_fixture(%{first_name: "John", last_name: "Doe", balance: 15000})
    invoice1 = invoice_fixture(%{total_amount_due: 10000}, student)
    invoice2 = invoice_fixture(%{total_amount_due: 10000}, student)

    session
    |> log_in_admin()
    |> visit("/billing/bulk_invoices/new")
    |> assert_has(css(".card-title", text: "Bulk Payment"))
    |> react_select("#student-name", "John Doe")
    |> assert_has(css(".account-balance", text: "$150.00"))
    |> pay_ivoice()
    |> assert_has(modal_box("Total amount must be greater than zero."))
    |> accept_modal()
    |> assert_has(css(".bulk-invoice__invoice-item", text: "#{invoice1.id}"))
    |> assert_has(css(".bulk-invoice__invoice-item", text: "#{invoice2.id}"))
    |> click(css("#all-invoices-selected"))
    |> assert_has(css("#total-amount-due", text: "$200.00"))
    |> react_select("#payment-method", "Balance")
    |> pay_ivoice()
    |> assert_has(modal_box("Balance amount is less than total amount due."))
    |> dismiss_modal()
    |> react_select("#payment-method", "Cash")
    |> pay_ivoice()
    |> assert_has(css(".title", text: "Invoice ##{invoice1.id} (paid)"))
  end
end

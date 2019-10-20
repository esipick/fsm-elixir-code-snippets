defmodule FlightWeb.API.InvoiceView do
  use FlightWeb, :view

  alias FlightWeb.API.{UserView, InvoiceView}

  def render("show.json", %{invoice: invoice}) do
    %{data: render("invoice.json", invoice: invoice)}
  end

  def render("invoice.json", %{invoice: invoice}) do
    %{
      id: invoice.id,
      user: render(UserView, "skinny_user.json", user: invoice.user),
      user_id: invoice.user_id,
      payment_option: invoice.payment_option,
      date: invoice.date,
      total: invoice.total,
      tax_rate: invoice.tax_rate,
      total_tax: invoice.total_tax,
      total_amount_due: invoice.total_amount_due,
      line_items: render_many(invoice.line_items, InvoiceView, "line_item.json", as: :line_item)
    }
  end

  def render("line_item.json", %{line_item: line_item}) do
    %{
      description: line_item.description,
      rate: line_item.rate,
      amount: line_item.amount,
      quantity: line_item.quantity
    }
  end

  def render("index.json", %{page: page}) do
    # TODO: render page
    %{
      page: nil,
      data:
        render_many(
          page,
          FlightWeb.API.InvoiceView,
          "invoice.json",
          as: :invoice
        )
    }
  end
end

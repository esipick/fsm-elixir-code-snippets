defmodule Flight.Billing.UpdateInvoice do
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CreateInvoice}

  def run(invoice, invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)

    result =
      case update_invoice(invoice, invoice_params) do
        {:ok, invoice} ->
          if pay_off == true do
            CreateInvoice.pay(invoice, school_context)
          else
            {:ok, invoice}
          end

        {:error, error} ->
          {:error, error}
      end

    result
  end

  defp update_invoice(invoice, invoice_params) do
    Invoice.changeset(invoice, invoice_params) |> Repo.update()
  end
end

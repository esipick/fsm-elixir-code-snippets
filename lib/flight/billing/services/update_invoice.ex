defmodule Flight.Billing.UpdateInvoice do
  alias Flight.Repo
  alias Flight.Billing.{Invoice, CreateInvoice}

  def run(invoice, invoice_params, school_context) do
    pay_off = Map.get(school_context.params, "pay_off", false)

    result = Repo.transaction(fn ->
      case update_invoice(invoice, invoice_params) do
        {:ok, invoice} ->
          if pay_off == true do
            case CreateInvoice.pay(invoice, school_context) do
              {:ok, invoice} -> invoice
              {:error, error} -> Repo.rollback(error)
            end
          else
            invoice
          end

        {:error, error} -> Repo.rollback(error)
      end
    end)

    result
  end

  defp update_invoice(invoice, invoice_params) do
    Invoice.changeset(invoice, invoice_params) |> Repo.update
  end
end

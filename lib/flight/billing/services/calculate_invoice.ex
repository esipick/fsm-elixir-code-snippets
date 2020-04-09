defmodule Flight.Billing.CalculateInvoice do
  alias FlightWeb.API.{DetailedTransactionForm}
  alias Flight.Billing

  def run(invoice_params, school_context) do
    school = school(school_context)
    tax_rate = school.sales_tax || 0

    invoice_attrs =
      Map.merge(
        invoice_params,
        %{"school_id" => school.id, "tax_rate" => tax_rate}
      )

    line_items =
      Enum.map(invoice_attrs["line_items"], fn x -> calculate_line_item(x, invoice_attrs, school_context) end)

    total = Enum.map(line_items, fn x -> x["amount"] end) |> Enum.sum() |> round
    total_tax = round(total * tax_rate / 100)

    invoice_attrs =
      Map.merge(invoice_attrs, %{
        "line_items" => line_items,
        "total_tax" => total_tax,
        "total" => total,
        "total_amount_due" => total + total_tax
      })

    {:ok, invoice_attrs}
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end

  defp calculate_line_item(line_item, invoice, school_context) do
    amount = if line_item_type(line_item) == :aircraft do
      calculate_aircraft_item_amount(line_item, invoice, school_context)
    else
      (line_item["quantity"] || 0) * (line_item["rate"] || 0)
    end

    Map.put(line_item, "amount", amount)
  end

  def line_item_type(line_item) do
    String.to_atom(line_item["type"])
  rescue
    ArgumentError -> line_item["type"]
  end

  defp calculate_aircraft_item_amount(line_item, invoice, school_context) do
    hobbs_start = line_item["hobbs_start"]
    hobbs_end = line_item["hobbs_end"]
    tach_start = line_item["tach_start"]
    tach_end = line_item["tach_end"]

    if hobbs_start && hobbs_end && tach_start && tach_end do
      calculate_from_hobbs_tach(line_item, invoice, school_context)
    else
      (line_item["quantity"] || 0) * (line_item["rate"] || 0)
    end
  end

  defp calculate_from_hobbs_tach(line_item, invoice, school_context) do
    current_user = school_context.assigns.current_user
    detailed_params = %{
      "aircraft_details" => line_item,
      "appointment_id" => invoice["appointment_id"],
      "creator_user_id" => current_user.id,
      "user_id" => invoice["user_id"] || current_user.id
    }
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, form} ->
        {transaction, _instructor_line_item, _, _aircraft_line_item, _} =
          FlightWeb.API.DetailedTransactionForm.to_transaction(
            form,
            Billing.rate_type_for_form(form, school_context),
            school_context
          )

        transaction.total

      {:error, _changeset} ->
        0
    end
  end
end

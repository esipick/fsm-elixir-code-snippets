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

    case calculate_line_items(invoice_attrs, school_context) do
      {:ok, line_items} ->
        total = Enum.map(line_items, fn x -> x["amount"] end) |> Enum.sum() |> round

        total_taxable = Enum.map(line_items, &taxable_amount/1) |> Enum.sum()

        total_tax = round(total_taxable * tax_rate / 100)

        invoice_attrs =
          Map.merge(invoice_attrs, %{
            "line_items" => line_items,
            "total_tax" => total_tax,
            "total" => total,
            "total_amount_due" => total + total_tax
          })

        {:ok, invoice_attrs}

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp taxable_amount(line_item) do
    if Enum.member?(["true", true, 1], line_item["taxable"]) do
      line_item["amount"]
    else
      0
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end

  defp calculate_line_items(invoice_attrs, school_context) do
    calculated_items =
      Enum.map(invoice_attrs["line_items"], fn x ->
        calculate_line_item(x, invoice_attrs, school_context)
      end)

    errors =
      Enum.map(calculated_items, fn x ->
        case x do
          {:error, errors} -> errors
          _ -> nil
        end
      end)
      |> Enum.filter(fn x -> x end)

    if Enum.any?(errors) do
      {:error, Enum.at(errors, 0)}
    else
      line_items =
        Enum.map(calculated_items, fn x ->
          case x do
            {:ok, li} -> li
            _ -> nil
          end
        end)
        |> Enum.filter(fn x -> x end)

      {:ok, line_items}
    end
  end

  defp calculate_line_item(line_item, invoice, school_context) do
    case calculate_amount_and_rate(line_item, invoice, school_context) do
      {:ok, {amount, rate, qty}} ->
        {:ok, Map.merge(line_item, %{"amount" => amount, "rate" => rate, "quantity" => qty})}

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp calculate_amount_and_rate(line_item, invoice, school_context) do
    if line_item_type(line_item) == :aircraft && line_item["hobbs_tach_used"] do
      case calculate_from_hobbs_tach(line_item, invoice, school_context) do
        {:ok, amount} -> {:ok, {amount, amount, 1}}
        {:error, errors} -> {:error, errors}
      end
    else
      rate = line_item["rate"] || 0
      qty = line_item["quantity"] || 0
      amount = qty * rate

      {:ok, {amount, rate, qty}}
    end
  end

  def line_item_type(line_item) do
    String.to_atom(line_item["type"])
  rescue
    ArgumentError -> line_item["type"]
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

        {:ok, transaction.total}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end

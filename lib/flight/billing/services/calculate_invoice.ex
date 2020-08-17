defmodule Flight.Billing.CalculateInvoice do
  alias FlightWeb.API.{DetailedTransactionForm}
  alias Flight.Billing
  alias Flight.Repo
  alias Flight.Scheduling.Aircraft
  alias FlightWeb.ViewHelpers

  def run(invoice_params, school_context) do
    school = school(school_context)
    tax_rate = school.sales_tax || 0

    invoice_attrs =
      Map.merge(
        invoice_params,
        %{"school_id" => school.id, "tax_rate" => tax_rate}
      )

    line_items = calculate_line_items(invoice_attrs, school_context)
    total = Enum.map(line_items, &chargeable_amount/1) |> Enum.sum() |> round

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
  end

  defp taxable_amount(line_item) do
    if Enum.member?(["true", true, 1], line_item["taxable"]) do
      line_item["amount"]
    else
      0
    end
  end

  def chargeable_amount(line_item) do
    if Enum.member?(["true", true, 1], line_item["deductible"]) do
      -line_item["amount"]
    else
      line_item["amount"]
    end
  end

  defp school(school_context) do
    Flight.SchoolScope.get_school(school_context)
  end

  defp calculate_line_items(invoice_attrs, school_context) do
    Enum.map(invoice_attrs["line_items"], fn x ->
      calculate_line_item(x, invoice_attrs, school_context)
    end)
  end

  defp calculate_line_item(line_item, invoice, school_context) do
    if line_item_type(line_item) == :aircraft do
      if line_item["aircraft_id"] do
        calculate_aircraft_item(line_item, invoice, school_context)
      else
        line_item
      end
    else
      rate = line_item["rate"] || 0
      qty = line_item["quantity"] || 0
      amount = qty * rate

      Map.merge(line_item, %{"amount" => round(amount), "rate" => rate, "quantity" => qty})
    end
  end

  def line_item_type(line_item) do
    String.to_atom(line_item["type"])
  rescue
    ArgumentError -> line_item["type"]
  end

  defp calculate_aircraft_item(line_item, invoice, school_context) do
    current_user = school_context.assigns.current_user
    aircraft_details =
      line_item
      |> MapUtil.atomize_shallow()
      |> Map.merge(%{ignore_last_time: invoice["ignore_last_time"]})

    detailed_params = %{
      aircraft_details: aircraft_details,
      appointment_id: invoice["appointment_id"],
      creator_user_id: current_user.id,
      user_id: invoice["user_id"] || current_user.id
    }

    line_item
    |> calculate_from_hobbs_tach(detailed_params, school_context)
    |> validate_aircraft_item(detailed_params)
  end

  defp calculate_from_hobbs_tach(line_item, detailed_params, school_context) do
    form = struct(DetailedTransactionForm, detailed_params)
    rate_type = Billing.rate_type_for_form(form, school_context)

    hobbs_start = form.aircraft_details.hobbs_start || 0
    hobbs_end = form.aircraft_details.hobbs_end || form.aircraft_details.hobbs_start || 0

    qty = (hobbs_end - hobbs_start) / 10.0
    qty = if qty <= 0, do: 1, else: qty

    {transaction, _, _, _, _} =
      DetailedTransactionForm.to_transaction(form, rate_type, school_context)

    aircraft = Repo.get(Aircraft, form.aircraft_details.aircraft_id)

    rate =
      case rate_type do
        :normal -> aircraft.rate_per_hour
        :block -> aircraft.block_rate_per_hour
      end
    
    {rate, amount} = 
      if line_item["enable_rate"] && line_item["rate"] > 0 do
        rate = line_item["rate"]
        amount = Billing.aircraft_cost!(form.aircraft_details.hobbs_start, form.aircraft_details.hobbs_end, rate, 0.0)
        {rate, amount}

      else
        {rate, transaction.total}
      end 

    IO.inspect(rate, label: "RATEEE")
    IO.inspect(amount, label: "Amount")
    
    Map.merge(line_item, %{
      "amount" => round(amount),
      "rate" => rate,
      "quantity" => qty
    })
  rescue
    _e -> line_item
  end

  defp validate_aircraft_item(line_item, detailed_params) do
    changeset = DetailedTransactionForm.changeset(%DetailedTransactionForm{}, detailed_params)

    {line_item, should_validate} = 
      with {:ok, appointment} <- Flight.Scheduling.get_appointment_dangrous(Map.get(detailed_params, :appointment_id)) do
          fix_aircraft_hours(appointment, line_item)
      else
        _ -> {line_item, true}        
      end
    
    with true <- should_validate,
      {:ok, _} <- Ecto.Changeset.apply_action(changeset, :insert) do
        line_item
    
    else
      {:error, errors} ->
        Map.merge(line_item, %{"errors" => ViewHelpers.translate_errors(errors)})

      _ -> line_item
    end
  end

  defp fix_aircraft_hours(appointment, aircraft) do
      aircraft = 
          if appointment.start_tach_time, do: Map.put(aircraft, "tach_start", appointment.start_tach_time), else: aircraft
        
        aircraft = 
          if appointment.end_tach_time do
              Map.put(aircraft, "tach_end", appointment.end_tach_time)
          else 
            aircraft
          end

        aircraft = 
          if appointment.start_hobbs_time, do: Map.put(aircraft, "hobbs_start", appointment.start_hobbs_time), else: aircraft
        
        aircraft = 
          if appointment.end_hobbs_time do
              Map.put(aircraft, "hobbs_end", appointment.end_hobbs_time) 
          else
              aircraft
          end

        {aircraft, appointment.end_hobbs_time == nil} # if hobbs time is nil, it means its a new invoice and then validate it
  end
end

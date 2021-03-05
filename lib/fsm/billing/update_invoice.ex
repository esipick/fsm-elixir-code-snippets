defmodule Fsm.Billing.UpdateInvoice do
    alias Flight.Repo
    alias Fsm.Billing.{Invoice, CreateInvoice, LineItemCreator}
    alias Fsm.Scheduling.Aircraft
    alias Fsm.Billing.Services.Utils
    alias Fsm.Billing  
    alias Fsm.Accounts

    def run(invoice_input, pay_off, school_id, user_id) do
        pay_off = pay_off || false
        invoice_id = Map.get(invoice_input, :id)
        invoice = Billing.get_invoice(invoice_id)
        invoice_params = %{
          "id" => Map.get(invoice_input, :id),
          "appointment_id" => Map.get(invoice_input, :appointment_id),
          "demo" => Map.get(invoice_input, :demo) || invoice.demo,
          "date" => Map.get(invoice_input, :date),
          "ignore_last_time" => Map.get(invoice_input, :ignore_last_time),
          "is_visible" => Map.get(invoice_input, :is_visible),
          "payer_name" => Map.get(invoice_input, :payer_name),
          "payment_option" => Map.get(invoice_input, :payment_option),
          "tax_rate" => Map.get(invoice_input, :tax_rate),
          "total" => Map.get(invoice_input, :total),
          "total_amount_due" => Map.get(invoice_input, :total_amount_due),
          "total_tax" => Map.get(invoice_input, :total_tax),
          "user_id" => Map.get(invoice_input, :user_id),
          "line_items" => Map.get(invoice_input, :line_items)
        }

        %{roles: _roles, user: current_user} = Accounts.get_user(user_id)
        school = Fsm.SchoolScope.get_school(school_id)
        school_context = %Plug.Conn{assigns: %{current_user: current_user}}
        invoice_attribs = invoice_attrs(invoice_params, current_user)
        aircraft_info = Utils.aircraft_info_map(invoice_params)

      {:ok, invoice_attribs} = Flight.Billing.CalculateInvoice.run(invoice_attribs, school_context)
  
      {invoice_attribs, update_hours} = 
        if Map.get(invoice, :aircraft_info) == nil do
          {Map.put(invoice_attribs, "aircraft_info", aircraft_info), true}
  
        else 
          {invoice_attribs, false}
        end
  
      line_items = Map.get(invoice_attribs, "line_items") || []
  
      with {:aircrafts, false} <- Utils.multiple_aircrafts?(line_items),
        {:rooms, false} <- Utils.same_room_multiple_items?(line_items),
        {:ok, invoice} <- update_invoice(invoice, invoice_attribs) do
          line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)
  
          cond do
            invoice.appointment_id != nil -> Utils.update_aircraft(invoice, current_user)
            update_hours && line_item != nil -> Utils.update_aircraft(line_item.aircraft_id, line_item, current_user)
            true -> :nothing
          end
  
          if pay_off == true do

            invoice =
              if Map.get(invoice_input, :stripe_token) not in [nil, ""] do
                Map.put(invoice, :stripe_token, Map.get(invoice_input, :stripe_token))

              else
                invoice
              end
            CreateInvoice.pay(invoice, school_context)
          else
            {:ok, invoice}
          end
      else
        {:aircrafts, true} -> {:error, "An invoice can have a single item for Flight, Demo Flight or Simulator Hours."}
        {:rooms, true} -> {:error, "The same room cannot be added twice to an invoice."}
        error -> {:error, :failed}
      end
    end
  
    defp update_invoice(invoice, invoice_params) do
      Invoice.changeset(invoice, invoice_params) |> Repo.update()
    end
  
    defp invoice_attrs(invoice_params, current_user) do
      case invoice_params["line_items"] do
        nil ->
          invoice_params
  
        raw_line_items ->
          line_items = LineItemCreator.populate_creator(raw_line_items, current_user)
  
          Map.merge(invoice_params, %{"line_items" => line_items})
      end
    end
  
    defp update_aircraft(invoice) do
      line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)
  
      if line_item && line_item.hobbs_end && line_item.tach_end do
        aircraft = Repo.get(Aircraft, line_item.aircraft_id)
  
        {:ok, _} =
          aircraft
          |> Aircraft.changeset(%{
            last_tach_time: max(aircraft.last_tach_time, line_item.tach_end),
            last_hobbs_time: max(aircraft.last_hobbs_time, line_item.hobbs_end)
          })
          |> Flight.Repo.update()
      end
    end
  end
  
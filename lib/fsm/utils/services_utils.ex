defmodule Fsm.Billing.Services.Utils do
    alias Fsm.Scheduling.{Appointment, Aircraft}
    alias Flight.Repo
    alias Fsm.Billing.BillingQueries
    alias Fsm.Billing.{
        Invoice,
        InvoiceLineItem
    }


    def aircraft_info_map(%{"line_items" => line_items}) do
        line_item = Enum.find(line_items, fn i -> Map.get(i, "type") == "aircraft" end) 

        if line_item do
            Map.take(line_item, ["hobbs_end", "hobbs_start", "tach_end", "tach_start"])
        end
    end
    def aircraft_info_map(_), do: nil

    def multiple_aircrafts?(nil), do: {:aircrafts, false}
    def multiple_aircrafts?(line_items) do
        line_items = Enum.filter(line_items, fn i -> Map.get(i, "type") == "aircraft" || Map.get(i, :type) == :aircraft end) 

        {:aircrafts, Enum.count(line_items) > 1}
    end

    def same_room_multiple_items?(nil), do: {:rooms, false}
    def same_room_multiple_items?(line_items) do
        {:rooms,
        Enum.reduce(line_items, %{}, fn item, acc -> 
            key = Map.get(item, "room_id") || Map.get(item, :room_id)
            
            if key do
                rooms = Map.get(acc, key) || []
                Map.put(acc, key, [item | rooms])
            else
                acc
            end
        end)
        |> Map.values
        |> Enum.any?(&(Enum.count(&1) > 1))}
    end
    
    def update_aircraft(invoice, user) do
        line_item = Enum.find(invoice.line_items, fn i -> i.type == :aircraft end)

        with {:ok, apmnt} <- Flight.Scheduling.get_appointment_dangrous(invoice.appointment_id) do
            first_time = !apmnt.start_tach_time && !apmnt.end_tach_time && !apmnt.start_hobbs_time && !apmnt.end_hobbs_time
            should_update = first_time && line_item && line_item.hobbs_end && line_item.tach_end
            
            if should_update do
                aircraft = Repo.get(Aircraft, line_item.aircraft_id)
                
                apmnt = 
                    apmnt
                    |> Appointment.changeset(%{
                        start_tach_time: aircraft.last_tach_time,
                        end_tach_time: line_item.tach_end,
                        start_hobbs_time: aircraft.last_hobbs_time,
                        end_hobbs_time: line_item.hobbs_end
                    }, 0)
                
                changeset = 
                    aircraft
                    |> Aircraft.changeset(%{
                        last_tach_time: line_item.tach_end,
                        last_hobbs_time: line_item.hobbs_end
                    })

                with {:ok, _apmnt} <- Repo.update(apmnt),
                    {:ok, changeset} <- Repo.update(changeset) do
                        info = %{
                            aircraft_id: changeset.id,
                            hobbs_start: aircraft.last_hobbs_time / 10,
                            hobbs_end: changeset.last_hobbs_time / 10,
                            tach_start: aircraft.last_tach_time / 10,
                            tach_end: changeset.last_tach_time / 10
                        }
            
                        log_aircraft_time_change(user, info)
                        {:ok, changeset}
                end
            end
        end
    end

    def update_aircraft(nil, _map, _), do: {:ok, :done}
    def update_aircraft(aircraft_id, %{tach_end: tach_end, hobbs_end: hobbs_end}, user) do
        aircraft = Repo.get(Aircraft, aircraft_id)
        changeset = 
            aircraft
            |> Aircraft.changeset(%{
                last_tach_time: tach_end,
                last_hobbs_time: hobbs_end
            })
        
        with {:ok, changeset} <- Repo.update(changeset) do
            info = %{
                aircraft_id: changeset.id,
                hobbs_start: aircraft.last_hobbs_time / 10,
                hobbs_end: changeset.last_hobbs_time / 10,
                tach_start: aircraft.last_tach_time / 10,
                tach_end: changeset.last_tach_time / 10
            }

            log_aircraft_time_change(user, info)
            {:ok, changeset}
        end
    end
    def update_aircraft(_, _map, _), do: {:ok, :done}

    def log_aircraft_time_change(%{id: user_id, school_id: school_id}, %{
        aircraft_id: _aircraft_id, 
        hobbs_start: hobbs_start, 
        hobbs_end: hobbs_end, 
        tach_start: tach_start, 
        tach_end: tach_end} = info) do

            info =
                info
                |> Map.put(:user_id, user_id)
                |> Map.put(:school_id, school_id)

            cond do
                hobbs_start != hobbs_end && tach_start != tach_end ->
                    Flight.Log.record(:record_tach_time_change, info)
                    Flight.Log.record(:record_hobbs_time_change, info)

                hobbs_start != hobbs_end -> Flight.Log.record(:record_hobbs_time_change, info)
                tach_start != tach_end -> Flight.Log.record(:record_tach_time_change, info)
                true -> :ok
            end
    end

    def send_bulk_invoice_email(nil, _invoice_ids, _context), do: :ok
    def send_bulk_invoice_email(user_id, invoice_ids, %{assigns: %{current_user: %{school_id: school_id}}} = context) do
        user = Flight.Accounts.dangerous_get_user(user_id)
        school = Flight.SchoolScope.get_school(context)
        payment_date = 
            NaiveDateTime.utc_now()
            |> Flight.Walltime.utc_to_walltime(school.timezone)
            |> NaiveDateTime.to_date
            
        invoice =
            %{ids: invoice_ids, user_id: user_id, school_id: school_id}
            |> Queries.get_invoices_query 
            |> Repo.all
            |> Enum.filter(&(&1.total_amount_due > 0))
            |> Enum.reduce(%{}, fn invoice, acc -> 
                invoice = FlightWeb.Billing.InvoiceStruct.build_skinny(invoice)
                total = Map.get(acc, :total) || 0
                total_tax = Map.get(acc, :total_tax) || 0
                amount_paid = Map.get(acc, :amount_paid) || 0
                amount_remainder = Map.get(acc, :amount_remainder) || 0
                amount_due = Map.get(acc, :amount_due) || 0
                line_items = Map.get(acc, :line_items) || []

                if invoice.status == :paid do
                    %{
                        total: total + invoice.total,
                        total_tax: total_tax + invoice.total_tax,
                        amount_paid: amount_paid + invoice.amount_due,
                        amount_remainder: amount_remainder + 0,
                        amount_due: amount_due + invoice.amount_due,
                        line_items: line_items ++ invoice.line_items
                    }
                    
                else
                    %{
                        total: total + invoice.total,
                        total_tax: total_tax + invoice.total_tax,
                        amount_paid: amount_paid + invoice.amount_paid,
                        amount_remainder: amount_remainder + invoice.amount_remainder,
                        amount_due: amount_due + invoice.amount_due,
                        line_items: line_items ++ invoice.line_items
                    }
                end
            end)
            |> Map.put(:id, :rand.uniform(9999))
            |> Map.put(:user, user)
            |> Map.put(:payer_name, user.first_name <> " " <> user.last_name)
            |> Map.put(:payment_date, payment_date)
        
        line_items = Map.get(invoice, :line_items) || []
        line_items = Enum.sort(line_items, &(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at) == :lt))
        
        Flight.InvoiceEmail.deliver_email(Map.put(invoice, :line_items, line_items), school)
    end
end
defmodule Flight.Billing.Services.Utils do
    alias Flight.Scheduling.{Appointment, Aircraft}
    alias Flight.Repo

    def aircraft_info_map(%{"appointment_id" => apnmt_id, "line_items" => line_items}) when is_nil(apnmt_id) do
        line_item = Enum.find(line_items, fn i -> Map.get(i, "type") == "aircraft" end) 

        if line_item do
            Map.take(line_item, ["hobbs_end", "hobbs_start", "tach_end", "tach_start"])
        end
    end
    def aircraft_info_map(_), do: nil
    
    def update_aircraft(invoice) do
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
                
                aircraft = 
                    aircraft
                    |> Aircraft.changeset(%{
                        last_tach_time: line_item.tach_end,
                        last_hobbs_time: line_item.hobbs_end
                    })

                with {:ok, _apmnt} <- Repo.update(apmnt),
                    {:ok, aircraft} <- Repo.update(aircraft) do
                    {:ok, aircraft}
                end
            end
        end
    end

    def update_aircraft(nil, _map), do: {:ok, :done}
    def update_aircraft(aircraft_id, %{tach_end: tach_end, hobbs_end: hobbs_end}) do
        aircraft = Repo.get(Aircraft, aircraft_id)

        aircraft
        |> Aircraft.changeset(%{
            last_tach_time: tach_end,
            last_hobbs_time: hobbs_end
        })
        |> Repo.update
    end
    def update_aircraft(_, _map), do: {:ok, :done}
end
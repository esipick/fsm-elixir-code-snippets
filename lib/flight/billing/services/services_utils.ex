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

    def multiple_aircrafts?(nil), do: true
    def multiple_aircrafts?(line_items) do
        line_items = Enum.filter(line_items, fn i -> Map.get(i, "type") == "aircraft" || Map.get(i, :type) == :aircraft end) 

        Enum.count(line_items) > 1
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
end
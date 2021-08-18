defmodule Fsm.Aircrafts.ExpiredInspection do
    use Timex
    
    alias Fsm.Aircrafts.Inspection
    alias Fsm.Aircrafts.InspectionData
    alias Fsm.Aircrafts.InspectionQueries
    alias Flight.Repo
    
    defstruct [:aircraft, :inspection, :description, :status]
  
    def inspections_for_aircrafts(aircrafts) do

    inspections_query = InspectionQueries.get_not_completed_inspections_query()

      inspections =
        aircrafts
        |> Repo.preload([inspections: {inspections_query, [:inspection_data, :aircraft]}])
        |> Enum.map(& &1.inspections)
        |> List.flatten()
        |> Enum.map(fn(inspection) ->
            inspection_data = inspection.inspection_data
                |> Enum.reduce(%{}, fn (item, agg) ->
                    value = InspectionData.value_from_t_field(item)
                    case item.class_name do
                       "last_inspection" -> 
                            Map.put(agg, :last_inspection, value)
                        "next_inspection" ->
                            Map.put(agg, :next_inspection, value)
                    end
                end)
            Map.merge(inspection, inspection_data)
        end)
    
      Enum.reduce(inspections, [], fn inspection, expired_inspections ->
        case inspection_status(inspection) do
          status when status in [:expiring, :expired] ->
            [
              %__MODULE__{
                aircraft: inspection.aircraft,
                inspection: inspection,
                description: inspection_description(inspection),
                status: status
              }
              | expired_inspections
            ]
  
          _ ->
            expired_inspections
        end
      end)
    end
  
    def inspection_description(inspection) do
      case inspection.date_tach do
        :date ->
            Flight.Date.format(inspection.next_inspection)
        :tach ->
            tach_time = inspection.next_inspection - inspection.aircraft.last_tach_time
            FlightWeb.ViewHelpers.display_hour_tenths(tach_time)
      end
    end
  
    def inspection_status(inspection, today \\ nil) do
      now =
        case today do
          nil ->
            %{school: school} = Flight.Repo.preload(inspection.aircraft, :school)
            Timex.now(school.timezone)
  
          today ->
            today
        end

        case inspection.date_tach do
            :date ->
                case Timex.Interval.new(from: now, until: inspection.next_inspection) do
                    {:error, :invalid_until} ->
                      :expired
            
                    interval ->
                      duration = Timex.Interval.duration(interval, :hours)
            
                      tach_time = case duration <= 20 && duration > 0 do
                        true -> :expiring
                        false -> :good
                      end
                  end
            :tach ->
                interval = inspection.next_inspection - inspection.aircraft.last_tach_time
                cond do
                    interval < 20 && interval > 0 -> :expiring
                    interval <= 0 -> :expired
                    true -> :good
                end
            _ ->
                :good
        end
    end
end

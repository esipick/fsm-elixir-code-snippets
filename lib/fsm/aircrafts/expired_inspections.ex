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

    def inspection_description(inspection, today \\ nil) do
      case inspection.date_tach do
        :date ->

          now =
            case today do
              nil ->
                %{school: school} = Flight.Repo.preload(inspection.aircraft, :school)
                Timex.now(school.timezone)

              today ->
                today
            end
          duration = case Timex.Interval.new(from: now, until: inspection.next_inspection) do
            {:error, :invalid_until} ->
              "0 day(s) left"
            interval ->
              duration = Timex.Interval.duration(interval, :hours)
              IO.inspect(duration, label: "duration++++")
              Integer.to_string(duration) <> " day(s) left"
          end
          duration
        :tach ->
            # aircraft last_tach_time is store in db with factor 10
            tach_time = (inspection.next_inspection * 10) - (inspection.aircraft.last_tach_time)
            tach_time = case tach_time < 0 do
              true->
                0
              false->
                tach_time
            end
            IO.inspect(tach_time, label: "tach_time++++")
            FlightWeb.ViewHelpers.display_hour_tenths(tach_time) <>  " hrs"
      end
    end
    def last_inspection_description(inspection) do
      case inspection.date_tach do
        :date ->
          Flight.Date.format(inspection.last_inspection)
        :tach ->
          tach_time = (inspection.last_inspection * 10)
          FlightWeb.ViewHelpers.display_hour_tenths(tach_time)
      end
    end
    def next_inspection_description(inspection) do
      case inspection.date_tach do
        :date ->
          Flight.Date.format(inspection.next_inspection)
        :tach ->
          tach_time = (inspection.next_inspection * 10)
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

                      case duration <= inspection.aircraft.days_before && duration > 0 do
                        true -> :expiring
                        false -> :good
                      end
                  end
            :tach ->
              # aircraft last_tach_time is store in db with factor 10
                interval = (inspection.next_inspection * 10) - inspection.aircraft.last_tach_time
                IO.inspect(interval, label: "interval++++")
                cond do
                    interval < inspection.aircraft.tach_hours_before && interval > 0 -> :expiring
                    interval <= 0 -> :expired
                    true -> :good
                end
            _ ->
                :good
        end
    end

    def inspection_is_due(inspection) do
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
      inspection =  %{inspection | last_inspection: inspection_data.last_inspection}
      inspection =  %{inspection | next_inspection: inspection_data.next_inspection}

      case inspection_status(inspection) do
        :expiring -> inspection.next_inspection
        _ -> false
      end
    end
end

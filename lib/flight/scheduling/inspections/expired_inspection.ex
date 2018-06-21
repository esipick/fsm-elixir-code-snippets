defmodule Flight.Scheduling.ExpiredInspection do
  defstruct [:aircraft, :inspection, :description, :status]

  alias Flight.Scheduling.{Inspection, DateInspection, TachInspection}

  def inspections_for_aircrafts(aircrafts) do
    inspections =
      aircrafts
      |> Flight.Repo.preload(:inspections)
      |> Enum.map(& &1.inspections)
      |> List.flatten()

    inspections = Flight.Repo.preload(inspections, :aircraft)

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
    case Inspection.to_specific(inspection) do
      %DateInspection{expiration: expiration} -> Flight.Date.format(expiration)
      %TachInspection{tach_time: tach_time} -> "#{tach_time}"
    end
  end

  def inspection_status(inspection, today \\ Date.utc_today()) do
    case Inspection.to_specific(inspection) do
      %DateInspection{expiration: expiration} when not is_nil(expiration) ->
        interval =
          Timex.Interval.new(from: today, until: expiration)
          |> Timex.Interval.duration(:days)

        cond do
          interval < 30 && interval > 0 ->
            :expiring

          interval <= 0 ->
            :expired

          true ->
            :good
        end

      %TachInspection{tach_time: tach_time} when not is_nil(tach_time) ->
        interval = tach_time - inspection.aircraft.last_tach_time

        cond do
          interval < 10 && interval > 0 -> :expiring
          interval <= 0 -> :expired
          true -> :good
        end

      _ ->
        :good
    end
  end
end
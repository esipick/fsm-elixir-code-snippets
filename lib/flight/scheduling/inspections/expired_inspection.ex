defmodule Flight.Scheduling.ExpiredInspection do
  use Timex

  alias Flight.Scheduling.{Inspection, DateInspection, TachInspection}

  defstruct [:aircraft, :inspection, :description, :status]

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
      %DateInspection{expiration: expiration} ->
        Flight.Date.format(expiration)

      %TachInspection{tach_time: tach_time} ->
        FlightWeb.ViewHelpers.display_hour_tenths(tach_time)
    end
  end

  def inspection_status(inspection, today \\ nil) do
    time_now =
      if today do
        today
      else
        %{school: school} = Flight.Repo.preload(inspection.aircraft, :school)

        NaiveDateTime.utc_now()
        |> Flight.Walltime.utc_to_walltime(school.timezone)
      end

    case Inspection.to_specific(inspection) do
      %DateInspection{expiration: expiration} when not is_nil(expiration) ->
        case Timex.Interval.new(from: time_now, until: expiration) do
          {:error, :invalid_until} ->
            :expired

          interval ->
            duration = Timex.Interval.duration(interval, :hours)

            if duration <= 20 && duration > 0 do
              :expiring
            else
              :good
            end
        end

      %TachInspection{tach_time: tach_time} when not is_nil(tach_time) ->
        interval = tach_time - inspection.aircraft.last_tach_time

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

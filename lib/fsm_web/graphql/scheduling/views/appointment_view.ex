defmodule FsmWeb.GraphQL.Scheduling.AppointmentView do
require Logger
  def map(record) when is_map(record) do
    appointment = Map.get(record, :appointment)
    other = Map.take(record, [:user, :instructor, :aircraft, :room, :simulator])
    Logger.info fn -> "other: #{inspect other}" end
    resp =
      Map.merge(appointment,
        other
      )
    Logger.info fn -> "resp: #{inspect resp}" end
    resp
end

  def map(records) when is_list(records) do
    Enum.map(records, fn record ->
      map(record)
    end)
  end

  def map(records) do
    records
  end
end

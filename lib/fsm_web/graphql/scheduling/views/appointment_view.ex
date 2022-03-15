defmodule FsmWeb.GraphQL.Scheduling.AppointmentView do
  def map(record) when is_map(record) do
    appointment = Map.get(record, :appointment)
    other = Map.take(record, [:user, :instructor, :aircraft, :room, :simulator, :mechanic])
    Map.merge(appointment,
      other
    )
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

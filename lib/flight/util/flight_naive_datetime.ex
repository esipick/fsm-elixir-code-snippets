defmodule Flight.NaiveDateTime do
  def to_json(datetime) do
    %{datetime | microsecond: {0, 0}} |> NaiveDateTime.to_iso8601()
  end
end

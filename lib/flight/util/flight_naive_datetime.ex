defmodule Flight.NaiveDateTime do
  def to_walltime_json(datetime, timezone) do
    %{Flight.Walltime.utc_to_walltime(datetime, timezone) | microsecond: {0, 0}}
    |> NaiveDateTime.to_iso8601()
  end
end

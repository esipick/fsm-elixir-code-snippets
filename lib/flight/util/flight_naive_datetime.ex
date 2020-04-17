defmodule Flight.NaiveDateTime do
  def to_json(datetime) do
    %{datetime | microsecond: {0, 0}} |> NaiveDateTime.to_iso8601()
  end

  def get_school_current_time(timezone) do
    NaiveDateTime.utc_now()
    |> Flight.Walltime.utc_to_walltime(timezone)
  end
end

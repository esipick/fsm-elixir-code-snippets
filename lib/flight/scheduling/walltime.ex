defmodule Flight.Walltime do
  def set_timezone(%NaiveDateTime{} = datetime, timezone) when is_binary(timezone) do
    timezone =
      case Timex.Timezone.get(timezone, datetime) do
        {:error, {:could_not_resolve_timezone, name, seconds_from_zeroyear, _utc_or_wall}} ->
          [period] = Tzdata.periods_for_time(name, seconds_from_zeroyear, :utc)
          Timex.Timezone.tzdata_to_timezone(period, name)

        timezone ->
          timezone
      end

    set_timezone(datetime, timezone)
  end

  def set_timezone(%NaiveDateTime{} = datetime, %Timex.TimezoneInfo{} = timezone) do
    %DateTime{
      calendar: datetime.calendar,
      year: datetime.year,
      month: datetime.month,
      day: datetime.day,
      hour: datetime.hour,
      minute: datetime.minute,
      second: datetime.second,
      microsecond: datetime.microsecond,
      time_zone: timezone.full_name,
      std_offset: timezone.offset_std,
      utc_offset: timezone.offset_utc,
      zone_abbr: timezone.abbreviation
    }
  end

  def to_naive_datetime(%DateTime{} = datetime) do
    %NaiveDateTime{
      calendar: datetime.calendar,
      year: datetime.year,
      month: datetime.month,
      day: datetime.day,
      hour: datetime.hour,
      minute: datetime.minute,
      second: datetime.second,
      microsecond: datetime.microsecond
    }
  end

  def utc_to_walltime(%NaiveDateTime{} = datetime, timezone) do
    datetime
    |> Timex.Timezone.convert(timezone)
    |> to_naive_datetime()
  end

  def walltime_to_utc(%NaiveDateTime{} = datetime, timezone) do
    datetime
    |> set_timezone(timezone)
    |> Timex.to_naive_datetime()
  end
end

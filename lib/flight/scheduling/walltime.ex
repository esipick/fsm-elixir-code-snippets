defmodule Flight.Walltime do
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
end

defmodule Flight.WalltimeTest do
  use Flight.DataCase

  describe "set_timezone/2" do
    test "Keeps hour but sets timezone" do
      timezone = Timex.Timezone.get("America/Denver")
      datetime = NaiveDateTime.utc_now()
      %DateTime{} = walltime = Flight.Walltime.set_timezone(datetime, timezone)

      assert walltime.year == datetime.year
      assert walltime.month == datetime.month
      assert walltime.day == datetime.day
      assert walltime.hour == datetime.hour
      assert walltime.minute == datetime.minute
      assert walltime.second == datetime.second
      assert walltime.microsecond == datetime.microsecond
      assert walltime.time_zone == timezone.full_name
      assert walltime.std_offset == timezone.offset_std
      assert walltime.utc_offset == timezone.offset_utc
      assert walltime.zone_abbr == timezone.abbreviation
    end
  end

  describe "to_naive_datetime/1" do
    test "strips timezone" do
      datetime = Timex.local()

      %NaiveDateTime{} = walltime = Flight.Walltime.to_naive_datetime(datetime)

      assert walltime.year == datetime.year
      assert walltime.month == datetime.month
      assert walltime.day == datetime.day
      assert walltime.hour == datetime.hour
      assert walltime.minute == datetime.minute
      assert walltime.second == datetime.second
      assert walltime.microsecond == datetime.microsecond
    end
  end
end

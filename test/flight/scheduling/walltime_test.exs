defmodule Flight.WalltimeTest do
  use Flight.DataCase

  alias Flight.Walltime

  describe "set_timezone/2" do
    test "Keeps hour but sets timezone" do
      datetime = NaiveDateTime.utc_now()
      timezone = Timex.Timezone.get("America/Denver", datetime)
      %DateTime{} = walltime = Walltime.set_timezone(datetime, "America/Denver")

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

      %NaiveDateTime{} = walltime = Walltime.to_naive_datetime(datetime)

      assert walltime.year == datetime.year
      assert walltime.month == datetime.month
      assert walltime.day == datetime.day
      assert walltime.hour == datetime.hour
      assert walltime.minute == datetime.minute
      assert walltime.second == datetime.second
      assert walltime.microsecond == datetime.microsecond
    end
  end

  describe "utc_to_walltime" do
    test "to and from walltime_to_utc returns the same date" do
      expected = ~N[2018-03-03 06:00:00]

      actual =
        expected
        |> Walltime.utc_to_walltime("America/Denver")
        |> Walltime.walltime_to_utc("America/Denver")

      assert expected == actual
    end
  end
end

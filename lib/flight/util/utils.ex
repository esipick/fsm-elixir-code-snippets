defmodule Flight.Utils do
    @secs_in_a_day 86000

    def add_months(%NaiveDateTime{} = date, no_of_months) do
        total_days = no_of_days_by_adding_months(date, no_of_months)
        due_date = NaiveDateTime.add(date, total_days * @secs_in_a_day)
        
        date
        |> Map.put(:year, due_date.year)
        |> Map.put(:month, due_date.month)
        |> Map.put(:day, due_date.day)
    end

    def no_of_days_by_adding_months(%NaiveDateTime{}, 0), do: 0
    def no_of_days_by_adding_months(%NaiveDateTime{year: yy, month: mm, day: day} = date, no_of_coming_months) do
        total_days = 
            Enum.reduce(mm+1..mm + no_of_coming_months, 0, fn(month, acc) -> 
                rem = rem(month, 12)
                years = floor(month / 12)

                month = if rem == 0, do: 12, else: rem

                days = month_last_day(yy + years, month)
                days + acc
            end)
        
        if no_of_coming_months < 12 do
            last_day = Timex.end_of_month(date)
            last_day.day - day + total_days
        else
            total_days
        end
    end

    def month_last_day(yy, mm) do
        :calendar.last_day_of_the_month(yy, mm)
    end

    def beginning_of_last_week(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(weeks: -1)
        |> Timex.beginning_of_week
    end

    def end_of_last_week(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(weeks: -1)
        |> Timex.end_of_week
    end

    def beginning_of_last_month(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(months: -1)
        |> Timex.beginning_of_month
    end

    def end_of_last_month(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(months: -1)
        |> Timex.end_of_month
    end

    def beginning_of_last_year(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(years: -1)
        |> Timex.beginning_of_year
    end

    def end_of_last_year(%NaiveDateTime{} = date \\ NaiveDateTime.utc_now()) do
        date
        |> Timex.shift(years: -1)
        |> Timex.end_of_year
    end

    def date_range_from_str(str) do
        parts = String.splite(str, "-")
        start_date = List.first(parts) || ""
        end_date = List.last(parts) || ""

        with {start_date, _} <- Integer.parse(start_date),
            {end_date, _} <- Integer.parse(end_date) do
                start_date = 
                    start_date
                    Timex.from_unix
                    |> Timex.to_naive_datetime

                end_date = 
                    start_date
                    Timex.from_unix
                    |> Timex.to_naive_datetime

                {start_date, end_date}

            else
              _ ->  {nil, nil}
        end
    end
end

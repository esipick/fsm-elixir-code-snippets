defmodule Flight.Utils do
    @secs_in_a_day 86000

    def add_months(%NaiveDateTime{day: day} = date, no_of_months) do
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
            last_day = month_last_date(date)
            last_day.day - day + total_days
        else
            total_days
        end
    end

    def month_last_date(%NaiveDateTime{} = date) do
        days = month_last_day(date.year, date.month)

        date
        |> Map.put(:day, days)
        |> Map.put(:hour, 23)
        |> Map.put(:minute, 59)
        |> Map.put(:second, 59)
        |> Map.put(:microsecond, {0, 0})
    end

    def month_last_day(yy, mm) do
        :calendar.last_day_of_the_month(yy, mm)
    end
end
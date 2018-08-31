defmodule Flight.BackgroundJob do
  alias Flight.Repo
  require Ecto.Query
  import Ecto.Query

  def send_upcoming_appointment_notifications() do
    appointments_count =
      Enum.reduce(Flight.Accounts.get_schools(), 0, fn school, acc ->
        appointments =
          NaiveDateTime.utc_now()
          |> Flight.Walltime.utc_to_walltime(school.timezone)
          |> Timex.shift(hours: 1)
          |> appointments_around(school)
          |> Repo.preload([:user, :instructor_user])

        for appointment <- appointments do
          Flight.PushNotifications.appointment_in_1_hour_notification(
            appointment.user,
            appointment
          )
          |> Mondo.PushService.publish()

          if appointment.instructor_user do
            Flight.PushNotifications.appointment_in_1_hour_notification(
              appointment.instructor_user,
              appointment
            )
            |> Mondo.PushService.publish()
          end
        end

        acc + Enum.count(appointments)
      end)

    appointments_count
  end

  def appointments_around(date, school_context) do
    date =
      date
      |> normalized_to_interval(30)

    lower_bound = Timex.shift(date, minutes: -1)
    upper_bound = Timex.shift(date, minutes: 1)

    from(
      a in Flight.Scheduling.Appointment,
      where: a.start_at > ^lower_bound and a.start_at < ^upper_bound
    )
    |> Flight.SchoolScope.scope_query(school_context)
    |> Repo.all()
  end

  def normalized_to_interval(%NaiveDateTime{} = date, intervalMinute) do
    {:ok, startOfHour} = NaiveDateTime.new(date.year, date.month, date.day, date.hour, 0, 0)
    diff = NaiveDateTime.diff(date, startOfHour, :second)
    intervalSeconds = intervalMinute * 60
    secondsInHour = 60 * 60
    secondsToAdd = Integer.mod(round(diff / intervalSeconds) * intervalSeconds, secondsInHour)
    newDate = Timex.shift(startOfHour, seconds: secondsToAdd)

    if secondsToAdd == 0 && diff > secondsInHour / 2 do
      newDate
      |> Timex.shift(hours: 1)
      |> Timex.to_naive_datetime()
    else
      newDate
      |> Timex.to_naive_datetime()
    end
  end

  def send_outstanding_payments_notifications() do
    outstanding_payment_user_ids()
    |> Enum.uniq()
    |> Enum.map(fn user_id ->
      user_id
      |> Flight.PushNotifications.outstanding_payment_request_notification()
      |> Mondo.PushService.publish()
    end)
    |> Enum.count()
  end

  def outstanding_payment_user_ids() do
    from(
      t in Flight.Billing.Transaction,
      select: t.user_id,
      where: t.state == "pending"
    )
    |> Repo.all()
  end
end

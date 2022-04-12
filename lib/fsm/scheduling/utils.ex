defmodule Fsm.Scheduling.Utils do
  require Logger

  @doc """
    Appointment ICS Generation
  """

  def url_for_appointment_ics(%{id: id} = appointment) do
    # create url and make a head request
    # if not present, make event file and upload.
    filename = "appointment-#{id}.ics"

    with {:error, _} <- check_if_exists(filename),
      {:ok, filename} <- create_event_file(appointment) do
        result = upload_to_s3(filename)
        File.rm(filename)
        result
    end
  end

  defp create_event_file(%{id: id, school: school} = appointment) do
    # attendees = [
    #   %{"PARTSTAT" => "ACCEPTED", "CN" => "eric@clockk.com", original_value: "mailto:eric@clockk.com"},
    #   %{"PARTSTAT" => "ACCEPTED", "CN" => "paul@clockk.com", original_value: "mailto:paul@clockk.com"},
    #   %{"PARTSTAT" => "ACCEPTED", "CN" => "James SM", original_value: "mailto:james@clockk.com"},
    # ]

    {start_at, end_at} =
      if appointment.instructor != nil do
        start_at = appointment.inst_start_at || appointment.start_at
        end_at = appointment.inst_end_at || appointment.end_at
        {start_at, end_at}
      else
        {appointment.start_at, appointment.end_at}
      end

    filename = "appointment-#{id}.ics"
    timezone = school.timezone || "Etc/UTC"

    start_at = Timex.to_datetime(start_at, timezone)
    end_at = Timex.to_datetime(end_at, timezone)

    address = school.address_1 || ""
    city = school.city || ""
    state = school.state || ""

    location =
      [school.name, address, city, state]
      |> Enum.filter(&(&1 != ""))
      |> Enum.join(", ")

    type =
      appointment.type
      |> to_string
      |> String.replace("_", "")
      |> String.capitalize

    title =
      cond do
        appointment.demo -> "Demo Flight"
        appointment.user != nil -> appointment.user.first_name <> " " <> appointment.user.last_name <> "'s #{type}"
        appointment.instructor != nil -> appointment.instructor.first_name <> " " <> appointment.instructor.last_name <> "'s #{type}"
        appointment.mechanic != nil -> appointment.mechanic.first_name <> " " <> appointment.mechanice.last_name <> "'s #{type}"
        true -> "Scheduled Appointment at #{school.name}"
      end

    event =
      %FsmCal.Event{
        summary: title,
        dtstart: start_at,
        dtend: end_at,
        description: "Your appointment #{type} is scheduled at #{school.name}",
        location: location
        # attendees: attendees
      }

    ics = %FsmCal{events: [event]} |> FsmCal.to_ics(alarm: 60) # with 60 mins alert

    with :ok <- File.write(filename, ics) do
      {:ok, filename}

    else
      {:error, _} ->
        {:error, "Couldn't create file, Please try again."}
    end
  end

  defp check_if_exists(filename) do
    s3_bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]

    s3_bucket
    |> ExAws.S3.head_object(filename)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, make_url(filename)}
      error ->
        Logger.info(fn -> "#{inspect error}" end)
        {:error, :not_found}
    end
  end

  defp upload_to_s3(filename) do
    File.read(filename)
    |> case do
      {:ok, file_binary} ->
        s3_bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]

        s3_bucket
        |> ExAws.S3.put_object(filename, file_binary)
        |> ExAws.request()
        |> case do
          {:ok, _} -> {:ok, make_url(filename)}
          _ -> {:error, "couldn't upload file to bucket, please try agian."}
        end

      _ -> {:error, "Couldn't open the saved file, please try again."}
    end
  end

  defp make_url(filename) do
    bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]
    "https://s3.amazonaws.com/"<>bucket<>"/"<>filename
  end

  @doc """
    Appointment scheduling
  """
  def calculateSchedules(type, days, end_at, appt_start, appt_end, _timezone_offset) when is_nil(end_at) or is_nil(type) or is_nil(days), do: {appt_start, appt_end}
  def calculateSchedules(type, days, end_at, appt_start, appt_end, timezone_offset \\ 0) when is_list(days) do
    {:ok, appt_start} = if is_binary(appt_start), do: NaiveDateTime.from_iso8601(appt_start), else: {:ok, appt_start}
    {:ok, appt_end} = if is_binary(appt_end), do: NaiveDateTime.from_iso8601(appt_end), else: {:ok, appt_end}
    {:ok, end_at} = if is_binary(end_at), do: NaiveDateTime.from_iso8601(end_at), else: {:ok, end_at}

    duration = %Timex.Duration{seconds: timezone_offset, megaseconds: 0, microseconds: 0}
    local_appt_start = Timex.add(appt_start, duration)
    local_appt_end = Timex.add(appt_end, duration)
    local_end_at = Timex.add(end_at, duration)

    first = {local_appt_start, local_appt_end}
    schedules = generate_ranges(type, days, local_appt_start, local_appt_end, local_end_at, false)

    all = [first | schedules]

    Enum.map([first | schedules], fn {local_start_at, local_end_at} ->
      duration = %Timex.Duration{seconds: -timezone_offset, megaseconds: 0, microseconds: 0}
      appt_start = Timex.add(local_start_at, duration)
      appt_end = Timex.add(local_end_at, duration)

      {appt_start, appt_end}
    end)
  end

  def pre_post_instructor_duration(attrs) do
    start_at = Map.get(attrs, :start_at) || Map.get(attrs, "start_at")
    end_at = Map.get(attrs, :end_at) || Map.get(attrs, "end_at")
    inst_start_at = Map.get(attrs, :inst_start_at) || Map.get(attrs, "inst_start_at") || start_at
    inst_end_at = Map.get(attrs, :inst_end_at) || Map.get(attrs, "inst_end_at") || end_at

    {:ok, appt_start} = if is_binary(start_at), do: NaiveDateTime.from_iso8601(start_at), else: {:ok, start_at}
    {:ok, appt_end} = if is_binary(end_at), do: NaiveDateTime.from_iso8601(end_at), else: {:ok, end_at}
    {:ok, inst_start_at} = if is_binary(inst_start_at), do: NaiveDateTime.from_iso8601(inst_start_at), else: {:ok, inst_start_at}
    {:ok, inst_end_at} = if is_binary(inst_end_at), do: NaiveDateTime.from_iso8601(inst_end_at), else: {:ok, inst_end_at}

    pre_time = Timex.diff(appt_start, inst_start_at, :seconds)
    post_time = Timex.diff(inst_end_at, appt_end, :seconds)

    {abs(pre_time), abs(post_time)}
  end

  defp generate_ranges(type, days, appt_start, appt_end, end_at, next_iteration, schedules \\ []) do
    num_of_seconds_in_day = 86400
    today_num =  if type == :week, do: Timex.weekday(appt_start), else: appt_start.day
    days = Enum.sort(days, &(&1 < &2))

    iter_schedules =
      Enum.reduce(days, [], fn day, acc ->
        same_day = day <= today_num && !next_iteration

        if !same_day || day > today_num do
          diff = day - today_num
          duration = %Timex.Duration{seconds: diff * 86400, megaseconds: 0, microseconds: 0}
          next_end_at = Timex.add(appt_end, duration)

          if Timex.compare(end_at, next_end_at) >= 0 do
            next_start_at = Timex.add(appt_start, duration)
            schedule = {next_start_at, next_end_at}

            [schedule | acc]
          else
            acc
          end
        else
          acc
        end
      end)

    duration = %Timex.Duration{seconds: 1, megaseconds: 0, microseconds: 0}
    next_start = if type == :week, do: Timex.end_of_week(appt_start), else: Timex.end_of_month(appt_start)
    next_end = if type == :week, do: Timex.end_of_week(appt_end), else: Timex.end_of_month(appt_end)
    next_start = Timex.add(next_start, duration) # start of next day
    next_end = Timex.add(next_end, duration) # start of next day

    appt_start = %{next_start | hour: appt_start.hour, minute: appt_start.minute, second: appt_start.second}
    appt_end = %{next_end | hour: appt_end.hour, minute: appt_end.minute, second: appt_end.second}

    iterations = Timex.diff(end_at, appt_end, type) # number of months/weeks in duration

    if iterations >= 0 do
      generate_ranges(type, days, appt_start, appt_end, end_at, true, iter_schedules ++ schedules)

    else
      iter_schedules ++ schedules
    end
  end

  def integer_list(items) do
    Enum.reduce(items, [], fn item, acc ->
      int = string_to_int(item)
      if int != nil, do: [int | acc], else: acc
    end)
  end

  def string_to_int(nil), do: nil
  def string_to_int(str) when is_integer(str), do: str
  def string_to_int(str) do
    Integer.parse(str)
    |> case do
      {int, _} -> int
      _ -> nil
    end
  end
end

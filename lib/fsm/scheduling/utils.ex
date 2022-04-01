defmodule Fsm.Scheduling.Utils do
  require Logger

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
end

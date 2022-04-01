defmodule FsmCal.Event do
  @moduledoc """
  Calendars have events.
  """

  defstruct summary: nil,
            dtstart: nil,
            dtend: nil,
            rrule: nil,
            exdates: [],
            description: nil,
            location: nil,
            url: nil,
            uid: nil,
            prodid: nil,
            status: nil,
            categories: nil,
            class: nil,
            comment: nil,
            geo: nil,
            modified: nil,
            organizer: nil,
            sequence: nil,
            attendees: []
end

defimpl FsmCal.Serialize, for: FsmCal.Event do
  alias FsmCal.KV

  def to_ics(event, options \\ []) do
    contents =
      event
      |> to_kvs
      |> add_alarm(options)
    """
    BEGIN:VEVENT
    #{contents}END:VEVENT
    """
  end

  defp add_alarm(content, alarm: duration) do
    """
    #{content}
    BEGIN:VALARM
    TRIGGER:-PT#{duration}M
    DESCRIPTION:Scheduled Appointment
    ACTION:DISPLAY
    END:VALARM
    """
  end
  defp add_alarm(content, _), do: content

  defp to_kvs(event) do
    event
    |> Map.from_struct()
    |> Enum.map(&to_kv/1)
    |> List.flatten()
    |> Enum.sort()
    |> Enum.join()
  end

  defp to_kv({:exdates, value}) when is_list(value) do
    case value do
      [] ->
        ""

      exdates ->
        exdates
        |> Enum.map(&KV.build("EXDATE", &1))
    end
  end

  defp to_kv({key, value}) do
    name = key |> to_string |> String.upcase()
    KV.build(name, value)
  end
end

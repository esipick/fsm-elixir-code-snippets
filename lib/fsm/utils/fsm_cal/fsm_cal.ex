defmodule FsmCal do
  @moduledoc """
  Generating FsmCal.
  """

  defstruct events: []
  defdelegate to_ics(events, options \\ []), to: FsmCal.Serialize

  def encode_to_iodata(calendar, options \\ []) do
    {:ok, encode_to_iodata!(calendar, options)}
  end

  def encode_to_iodata!(calendar, _options \\ []) do
    to_ics(calendar)
  end
end

defimpl FsmCal.Serialize, for: FsmCal do
  def to_ics(calendar, options \\ []) do
    events = Enum.map(calendar.events, &FsmCal.Serialize.to_ics(&1, options))
    vendor = Keyword.get(options, :vendor, "Fsm ICalendar")

    """
    BEGIN:VCALENDAR
    CALSCALE:GREGORIAN
    VERSION:2.0
    PRODID:-//Fsm ICalendar//#{vendor}//EN
    #{events}END:VCALENDAR
    """
  end
end

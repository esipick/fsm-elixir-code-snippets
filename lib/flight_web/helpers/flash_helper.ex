defmodule FlightWeb.FlashHelper do
  def flash_token do
    Flight.Memoize.run(:flash_token, fn ->
      inspect(:os.system_time())
    end)
  end
end

defmodule FlightWeb.FlashHelper do
  def flash_token do
    inspect(:os.system_time())
  end
end

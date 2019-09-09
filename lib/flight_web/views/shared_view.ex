defmodule FlightWeb.SharedView do
  use FlightWeb, :view
  import Scrivener.HTML

  def page_sizes do
    [50, 75, 100]
  end
end

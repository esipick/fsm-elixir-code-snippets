defmodule FlightWeb.API.RenderHelpers do
  def json_errors(errors) do
    for {thing, {message, options}} <- errors do
      %{
        thing =>
          %{
            message: message
          }
          |> Map.merge(Enum.into(options, %{}))
      }
    end
  end
end

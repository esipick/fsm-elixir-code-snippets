defmodule FlightWeb.GraphQL.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  require Logger

  def call(resolution, role) do
    context = resolution.context || %{}
    # Logger.debug "Authorizzze #{inspect role}, context: #{inspect context}"
    case Map.get(context, :current_user) do
      nil ->
        Absinthe.Resolution.put_result(resolution, {:error, "unauthenticated"})
      _ ->
        check_role(resolution, role)
    end
  end

  defp check_role(resolution, role) do
    with %{current_user: current_user} <- resolution.context,
         true <- correct_role(current_user, role) do
      # Logger.debug "Allowed to login #{inspect current_user} #{inspect role}"
      resolution
    else
      _error ->
        # Logger.debug "authorize error #{inspect error}"
        resolution
        |> Absinthe.Resolution.put_result({:error, "unauthorized"})
    end
  end

  defp correct_role(_, []), do: true
  defp correct_role(%{role: role}, roles) when is_list(roles) do
    Enum.find(roles, &(&1 == role)) != nil
  end
  defp correct_role(_, :any), do: true
  defp correct_role(%{role: role}, role), do: true
  defp correct_role(_, _), do: false

end

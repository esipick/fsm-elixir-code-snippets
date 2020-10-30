defmodule FlightWeb.GraphQL.Middleware.UpdateContext do
  @behaviour Absinthe.Middleware

  def call(%{value: %{user: user}} = resolution, _) do
      update_context(resolution, user)
  end
  def call(%{value: %{session: %{user: user}}} = resolution, _) do
    update_context(resolution, user)
  end
  def call(res, _), do: res

  defp update_context(resolution, user) do
    %{resolution |
      context: Map.put(resolution.context,
        :current_user, %{id: user.id, role: user.active_role})}
  end
end

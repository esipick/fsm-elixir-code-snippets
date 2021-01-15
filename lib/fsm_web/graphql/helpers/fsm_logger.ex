defmodule FsmWeb.GraphQL.Log do
  require Logger

  @moduledoc """
  Custom Logger to log graphql `responses`
  """
  def request(request, {function_name, _}) do
    Logger.info fn -> "REQUEST func '#{inspect function_name}': args >> #{inspect request}" end
    request
  end

  def response(response, {function_name, _}, :error) do
    Logger.error fn -> "RESPONSE func '#{inspect function_name}': #{inspect response}" end
    response
  end

  def response(response, {function_name, _}, :debug) do
    Logger.debug fn -> "RESPONSE func '#{inspect function_name}': #{inspect response}" end
    response
  end

  def response(response, {function_name, _}, _info \\ nil) do
    Logger.info fn -> "RESPONSE func '#{inspect function_name}': #{inspect response}" end
    response
  end
end

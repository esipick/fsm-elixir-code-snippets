defmodule FsmWeb.GraphQL.EctoHelpers do
    alias Ecto.Changeset

    require Logger

    @doc """
    Transform `%Ecto.Changeset{}` errors to a map
    containing field name as a key on which validation
    error happened and it's formatted message.
    """
    def to_api_errors(%Changeset{} = changeset) do
        changeset
        |> format_errors()
       # |> concat_errors()
    end

    @doc """
    Wrap context actions with Ecto.
    If action succeeds then the result tuple returned.
    If changeset errors happen then all errors transformed
    into convenient form of list of maps with fields on
    which validations failed.
    Else `unknown` error returned.
    """
    def action_wrapped(fun) do
        case fun.() do
            {:ok, result} ->
                {:ok, result}

            {:error, changeset = %Changeset{}} ->
                {
                    :error,
                    %{
                    message: "Changeset errors occurred",
                    code: :schema_errors,
                    errors: to_api_errors(changeset)
                    }
                }

            # Case for our standard errors in `FbossWeb.GraphQL.Errors`
            {:error, %{code: _}} = error ->
                error

            {:error, detail} ->
                Logger.error fn -> "Error #{inspect detail}" end
                {
                    :error,
                    %{
                    message: detail,
                    code: :oops
                    }
                }
        end
    end

    # Extract and interpolate all errors from
    # `Changeset.errors` and return a map.
    defp format_errors(%Changeset{} = changeset) do
        Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, formatted_msg ->
            formatted_msg |> String.replace("%{#{key}}", to_string(value))
            end)
        end)
    end

  # Get all errors from `format_errors/1` and
  # join their messages into a single string
  # separated by ","
    defp concat_errors(errors) do
        Enum.reduce(errors, errors, fn {key, value}, map ->
            map |> Map.put(key, Enum.join(value, ", "))
        end)
    end
end

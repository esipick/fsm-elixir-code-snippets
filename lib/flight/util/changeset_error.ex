defmodule Flight.Ecto.Errors do

    def traverse(%Ecto.Changeset{} = changeset) do
        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", _to_string(value))
            end)
        end)
        |> Enum.reduce("", fn {k, v}, acc ->
            joined_errors = Enum.join(v, "; ")
            "#{acc}; #{k}: #{joined_errors}"
        end)
    end

    def traverse(changeset), do: changeset
  
    defp _to_string(val) when is_list(val) do
      Enum.join(val, ",")
    end
    defp _to_string(val), do: to_string(val)
end
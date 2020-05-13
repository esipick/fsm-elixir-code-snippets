defmodule MapUtil do
  def symbolize_keys(attrs) do
    attrs
    |> Map.new(fn {k, v} -> {if(is_atom(k), do: k, else: String.to_atom(k)), v} end)
  end
end

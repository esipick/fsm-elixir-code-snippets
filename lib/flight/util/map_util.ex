defmodule MapUtil do
  def atomize_shallow(attrs) do
    attrs
    |> Map.new(fn {k, v} -> {if(is_atom(k), do: k, else: String.to_atom(k)), v} end)
  end

  def atomize_deep(%{} = map) do
    map
    |> Enum.map(fn
      {key, %{} = value} -> {String.to_atom(key), atomize_deep(value)}
      {key, value} -> {String.to_atom(key), value}
    end)
    |> Enum.into(%{})
  end
end

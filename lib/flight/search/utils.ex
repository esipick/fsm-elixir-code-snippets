defmodule Flight.Search.Utils do
  @moduledoc """
  Common used helpers for full text search
  """
  @spec prefix_search(any()) :: String.t()
  def prefix_search(term) do
    term <> ":*"
  end

  @spec normalize(any()) :: String.t()
  def normalize(term) do
    term
    |> String.downcase()
    |> String.trim()
    |> String.split()
    |> Enum.map(fn x -> x |> String.replace(~r/\W/u, "") end)
    |> Enum.join(" & ")
  end
end

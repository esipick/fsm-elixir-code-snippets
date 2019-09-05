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
    |> String.downcase
    |> String.replace(~r/\W/u, "")
    |> String.trim
  end
end

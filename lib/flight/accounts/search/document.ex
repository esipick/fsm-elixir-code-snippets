defmodule Flight.Accounts.Search.Document do
  @moduledoc """
  Implementation of the full-text document search
  """

  import Ecto.Query
  alias Flight.Search.Utils

  @spec run(Ecto.Query.t(), any()) :: Ecto.Query.t()
  def run(query, search_term) do
    case normalized_term = Utils.normalize(search_term) do
      "" ->
        query

      _ ->
        where(
          query,
          fragment(
            "to_tsvector('english', file || ' ') @@ to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          )
        )
    end
  end
end

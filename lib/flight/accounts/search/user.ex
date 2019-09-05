defmodule Flight.Accounts.Search.User do
  @moduledoc """
  Implementation of the full-text user search
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
            "to_tsvector(
              'english',
              email || ' ' ||
              first_name || ' ' ||
              last_name || ' ' ||
              replace(phone_number, '-', '') || ' ' ||
              coalesce(address_1, ' ') || ' ' ||
              coalesce(city, ' ') || ' ' ||
              coalesce(zipcode, ' ') || ' ' ||
              coalesce(state, ' ')
            ) @@
            to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          )
        )
    end
  end
end

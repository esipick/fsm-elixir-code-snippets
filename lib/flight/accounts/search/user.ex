defmodule Flight.Accounts.Search.User do
  @moduledoc """
  Implementation of the full-text user search
  """

  import Ecto.Query
  alias Flight.Search.Utils

  @spec run(Ecto.Query.t(), any()) :: Ecto.Query.t()
  # def run(query, search_term) do
  #   if String.contains?(search_term, "@") do
  #     search_email(query, search_term)
  #   else
  #     search_name(query, search_term)
  #   end
  # end

  # def search_email(query, search_term) do
  #   case search_term do
  #     "" ->
  #       query

  #     _ ->
  #       where(
  #         query,
  #         fragment(
  #           "to_tsvector(
  #             'english',
  #             u0.email || ' ' ||
  #             u0.first_name || ' ' ||
  #             u0.last_name || ' ' ||
  #             replace(u0.phone_number, '-', '') || ' ' ||
  #             coalesce(u0.address_1, ' ') || ' ' ||
  #             coalesce(u0.city, ' ') || ' ' ||
  #             coalesce(u0.zipcode, ' ') || ' ' ||
  #             coalesce(u0.state, ' ')
  #           ) @@
  #           to_tsquery(?)",
  #           ^Utils.prefix_search(normalized_term)
  #         )
  #       )
  #   end
  # end

  def run(query, search_term) do
    normalized_term = Utils.normalize(search_term)

    case normalized_term do
      "" ->
        query

      _ ->
        where(
          query,
          fragment(
            "to_tsvector(
              'english',
              u0.first_name || ' ' ||
              u0.last_name || ' ' ||
              replace(u0.phone_number, '-', '') || ' ' ||
              coalesce(u0.address_1, ' ') || ' ' ||
              coalesce(u0.city, ' ') || ' ' ||
              coalesce(u0.zipcode, ' ') || ' ' ||
              coalesce(u0.state, ' ')
            ) @@
            to_tsquery(?) or u0.email ilike ?",
            ^Utils.prefix_search(normalized_term),
            ^"%#{search_term}%"
          )
        )
    end
  end

  @spec run(Ecto.Query.t(), any()) :: Ecto.Query.t()
  def name_only(query, search_term) do
    case normalized_term = Utils.normalize(search_term) do
      "" ->
        query

      _ ->
        where(
          query,
          fragment(
            "to_tsvector('english', first_name || ' ' || last_name) @@ to_tsquery(?)",
            ^Utils.prefix_search(normalized_term)
          )
        )
    end
  end
end

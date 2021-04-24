defmodule Flight.Accounts.Search.User do
  @moduledoc """
  Implementation of the full-text user search
  """

  import Ecto.Query
  alias Flight.Search.Utils

  @spec run(Ecto.Query.t(), any(), any(), any()) :: Ecto.Query.t()
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
require Logger
  def run(query, search_term, from_date, to_date) do
    normalized_term = Utils.normalize(search_term)

    cond do
      normalized_term in ["", nil, " "] && from_date in ["", nil, " "] && to_date in ["", nil, " "] ->
        query

      normalized_term in ["", nil, " "] && from_date not in ["", nil, " "] && to_date in ["", nil, " "] ->
        where(query, [u], u.inserted_at >= ^to_string(from_date<>" 00:00:00"))

      normalized_term in ["", nil, " "] && from_date in ["", nil, " "] && to_date not in ["", nil, " "] ->
        where(query, [u], u.inserted_at <= ^to_string(to_date<>" 23:59:59"))

      normalized_term in ["", nil, " "] && from_date not in ["", nil, " "] && to_date not in ["", nil, " "] ->
        where(query, [u], u.inserted_at >= ^to_string(from_date<>" 00:00:00") and u.inserted_at <= ^to_string(to_date<>" 23:59:59"))

      normalized_term not in ["", nil, " "] && from_date not in ["", nil, " "] && to_date not in ["", nil, " "] ->
        Logger.info fn -> "{from_date, to_date}: #{inspect {from_date, to_date}}"end
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
          ))
          |> where([u], u.inserted_at >= ^to_string(from_date<>" 00:00:00") and u.inserted_at <= ^to_string(to_date<>" 23:59:59"))

      true ->
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

#  @spec run(Ecto.Query.t(), any()) :: Ecto.Query.t()
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

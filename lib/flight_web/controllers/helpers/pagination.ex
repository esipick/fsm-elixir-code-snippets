defmodule FlightWeb.Pagination do
  def params(params) do
    %{
      page: Map.get(params, "page", 1),
      page_size: Map.get(params, "page_size", 50)
    }
  end

  def apply_headers(conn, page) do
    if page do
      Scrivener.Headers.paginate(conn, page)
    else
      conn
    end
  end
end

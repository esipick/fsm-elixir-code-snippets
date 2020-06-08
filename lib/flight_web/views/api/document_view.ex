defmodule FlightWeb.API.DocumentView do
  use FlightWeb, :view

  alias Flight.Accounts.Document
  alias FlightWeb.API.DocumentView

  def render("index.json", %{page: page, timezone: timezone}) do
    %{
      documents: render_many(page.entries, DocumentView, "show.json", timezone: timezone),
      page_number: page.page_number,
      page_size: page.page_size,
      total_entries: page.total_entries,
      total_pages: page.total_pages
    }
  end

  def render("show.json", %{document: document, timezone: timezone}) do
    today = DateTime.to_date(Timex.now(timezone))

    %{
      expired: Date.compare(document.expires_at || Date.add(today, 2), today),
      expires_at: document.expires_at,
      file: %{name: document.file.file_name, url: Document.file_url(document)},
      id: document.id,
      title: document.title || document.file.file_name
    }
  end
end

defmodule Flight.InvoiceUploader do
    use Waffle.Definition
    use Waffle.Ecto.Definition
    
    def storage_dir(_version, {_file, id}) do
      "uploads/#{Mix.env()}/invoices/#{id}/invoice.pdf"
    end
  
    def s3_object_headers(_version, {file, _scope}) do
      [content_type: MIME.from_path(file.file_name)]
    end
  end
  
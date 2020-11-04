defmodule Fsm.DocumentUploader do
    use Waffle.Definition
    use Waffle.Ecto.Definition
  
    def storage_dir(_version, {_file, scope}) do
      "uploads/#{Mix.env()}/user/#{scope.user_id}/documents/#{scope.id}"
    end
  
    def s3_object_headers(_version, {file, _scope}) do
      [content_type: MIME.from_path(file.file_name)]
    end
  end
  
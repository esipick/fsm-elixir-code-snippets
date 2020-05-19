defmodule Mix.Tasks.FixDocuments do
  use Mix.Task

  alias Flight.{Repo, Accounts.Document}

  @shortdoc "Updated document for adding to files content-type"
  def run(_) do
    [:postgrex, :ecto, :tzdata]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    IO.puts("Get documents")

    documents =
      Document
      |> Repo.all()

    for document <- documents do
      file_name = document.file.file_name
      bucket = System.get_env("AWS_S3_BUCKET")
      file = "uploads/#{Mix.env()}/user/#{document.user_id}/documents/#{document.id}/#{file_name}"
      path = "uploads/#{Mix.env()}/user/#{document.user_id}/documents/#{document.id}"
      content_type = MIME.from_path(file_name)

      IO.puts("download #{file_name}")
      File.mkdir_p(path)
      ExAws.S3.download_file(bucket, file, file)
      |> ExAws.request

      IO.puts("upload #{file_name}")
      local_image = File.read!(file)
      ExAws.S3.put_object(bucket, file, local_image, [content_type: content_type])
      |> ExAws.request()

      File.rm_rf(file)
    end

    IO.puts("Task completed successfully.")
  end
end

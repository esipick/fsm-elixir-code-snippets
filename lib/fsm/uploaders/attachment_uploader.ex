defmodule Fsm.AttachmentUploader do
  @doc """
  Returns a presigned url for file uploads
  """
  def get_presigned_url(inspection_id, file_ext) do
    bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]
    # max 20MB
    file_upload_max_size_in_bytes = System.get_env("FILE_UPLOAD_MAX_SIZE_IN_BYTES") || 20_000_000
    filename = Fsm.Helpers.make_attachment_filename(inspection_id, file_ext)

    ExAws.Config.new(:s3)
    |> ExAws.S3.presigned_url(
      :put,
      bucket,
      filename,
      query_params: [
        {"file_upload_max_size_in_bytes", file_upload_max_size_in_bytes},
        {"filename", filename},
        {"bucket", bucket}
      ]
    )
  end
end

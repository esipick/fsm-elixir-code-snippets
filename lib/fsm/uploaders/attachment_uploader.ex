defmodule Fsm.AttachmentUploader do
  @valid_formats ["jpeg", "jpg", "png", "vnd.microsoft.icon", "pdf"]

  @doc """
  Returns a presigned url for file uploads
  """
  def get_presigned_url(resource_id, file_ext) do
    bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]
    # max 20MB
    file_upload_max_size_in_bytes = System.get_env("FILE_UPLOAD_MAX_SIZE_IN_BYTES") || 20_000_000
    filename = Fsm.Helpers.make_attachment_filename(resource_id, file_ext)

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

  def upload_files_to_s3(_, []), do: {:ok, []}
  def upload_files_to_s3(resource_id, [%Plug.Upload{} = head | tail]) do
    all = [head | tail]
    Enum.reduce_while(all, {:ok, []}, fn attch, acc ->
      resource_id
      |> upload_file_to_s3(attch)
      |> case do
        {:ok, result} ->
          {:ok, acc} = acc
          {:cont, {:ok, [result | acc]}}

        {:error, msg} -> {:halt, {:error, msg}}
      end
    end)
  end

  def upload_file_to_s3(resource_id, %Plug.Upload{} = upload) do
    ext = file_extension(upload)
    with {:ok, ext} <- file_extension(upload),
      {:ok, size} <- valid_size(upload),
      {:ok, file_binary} <- File.read(upload.path) do
        s3_filename = Fsm.Helpers.make_attachment_filename(resource_id, ext)
        s3_bucket = Application.get_env(:ex_aws_s3, :s3)[:bucket_name]
        opts = [content_disposition: "inline; filename=#{s3_filename}", content_type: upload.content_type]

        s3_bucket
        |> ExAws.S3.put_object(s3_filename, file_binary, opts)
        |> ExAws.request()
        |> case do
          {:ok, _} ->
            item = %{
              url: s3_url_for_key(s3_bucket, s3_filename),
              file_name: upload.filename,
              file_extension: ext,
              size_in_bytes: size
            }
            {:ok, item}
          _ -> {:error, "Couldn't upload #{upload.filename} to s3, please try again."}
        end
     end
  end
  def upload_file_to_s3(_, _), do: :no_file

  def validate_attachment(attachments) do
    Enum.reduce_while(attachments, {:ok, :valid}, fn attch, _->
      with {:ok, _} <- file_extension(attch),
      {:ok, _} <- valid_size(attch) do
        {:cont, {:ok, :valid}}

      else
        other ->
          {:halt, other}
      end
    end)
  end

  defp valid_size(%Plug.Upload{} = upload) do
    path = Path.join(upload.path, upload.filename)

    File.stat(upload.path)
    |> case do
      {:ok, %{size: size}} ->
        file_size = Application.get_env(:flight, :file_size)
        human_size = Size.humanize!(file_size, spacer: "")

        if size > file_size do
          {:error, "#{upload.filename} size should not exceed #{human_size}"}

        else
          {:ok, file_size}
        end

      _ ->
        {:error, "something went wrong while uploading #{upload.filename}."}
    end
  end

  defp file_extension(%Plug.Upload{} = upload) do
    ext =
      upload.filename
      |> String.split(".")
      |> List.last

    parts = String.split(upload.content_type, "/")

    if List.last(parts) in @valid_formats do
      if ext in @valid_formats do
        {:ok, ext}

      else
        {:ok, Enum.find(@valid_formats, &(&1 == List.last(parts)))}
      end
    else
      {:error, "invalid filetype file: #{upload.filename}."}
    end
  end

  defp s3_url_for_key(bucket, key) do
    "https://s3.amazonaws.com/#{bucket}/#{key}"
  end
end

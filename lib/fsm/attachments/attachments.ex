defmodule Fsm.Attachments do
  @moduledoc """
  The Attachments context.
  """

  import Ecto.Query, warn: false
  alias Fsm.Repo
  alias Ecto.Multi
  alias Fsm.Helpers
  require Logger
  alias Fsm.Attachments.Attachment
  import Ecto.SoftDelete.Query

  @doc """
  Returns the Attachment.

  ## Examples

      iex> get_attachment()
      [%Attachment{}, ...]

  """

  def get_inspection_attachments(inspection_id) do
    Attachment
    |> where(inspection_id: ^inspection_id)
    |> with_undeleted
    |> Repo.all()
  end

  def get_attachment(id) do
    Attachment
    |> where(id: ^id)
    |> with_undeleted
    |> Repo.one()
  end

  def get_attachment_by_id_and_user_id(id, user_id) do
    Attachment
    |> where([id: ^id, user_id: ^user_id])
    |> with_undeleted
    |> Repo.one()
  end

  def add_attachment(attrs) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end

  def get_documents(user_id) do
    Attachment
    |> where([user_id: ^user_id, attachment_type: "document"])
    |> with_undeleted
    |> Repo.all()
  end

  def update_attachment(attachment, attrs) do
    attachment
    |> Attachment.changeset(attrs)
    |> Repo.update()
  end

  def delete_attachment_by_id(attachment, _, _) do
    Repo.soft_delete(attachment)
  end

  def delete_attachment_from_s3(_opt1, %{delete_attachment_by_id: %{url: url}}) do
    case Helpers.get_filename_from_url(url) do
      {:ok ,bucket, filename} ->

          ExAws.Config.new(:s3)
          ExAws.S3.delete_object(bucket, filename) |> ExAws.request()
        {:ok, true}
      {:error, error} ->
        {:error, error}
    end
  end

  def delete_attachment(attachment) do
    Multi.new
    |> Multi.run(:delete_attachment_by_id, &delete_attachment_by_id(attachment, &1, &2))
    |> Multi.run(:delete_attachment_from_s3, &delete_attachment_from_s3(&1, &2))
    |> Repo.transaction
    |> case  do
         {:ok, result} ->
           {:ok, result.delete_attachment_by_id}
         {:error, _error, error, %{}} ->
           {:error, error}
       end
  end

end

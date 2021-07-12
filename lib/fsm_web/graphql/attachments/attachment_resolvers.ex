defmodule FsmWeb.GraphQL.Attachments.AttachmentsResolvers do
  use FsmWeb.GraphQL.Errors
  alias FsmWeb.GraphQL.EctoHelpers
  alias Fsm.AttachmentUploader

  require Logger

  @doc """
  Returns a presigned url for file uploads
  """
  def get_presigned_url(_parent, %{inspection_id: id, file_ext: file_ext}, %{context: %{current_user: current_user}}) do
    url = AttachmentUploader.get_presigned_url(id, file_ext)
    {:ok, url}
  end

  def get_presigned_url(_parent, _args, _context), do: @not_authenticated
end

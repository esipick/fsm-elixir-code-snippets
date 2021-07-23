defmodule FsmWeb.GraphQL.Attachments.AttachmentsResolvers do
  use FsmWeb.GraphQL.Errors
  alias FsmWeb.GraphQL.EctoHelpers
  alias Fsm.AttachmentUploader
  alias Fsm.Attachments.Attachment

  require Logger

  @doc """
  Returns a presigned url for file uploads
  """
  def get_presigned_url(_parent, %{resource_id: id, file_ext: file_ext}, %{
        context: %{current_user: current_user}
      }) do
    AttachmentUploader.get_presigned_url(id, file_ext)
  end

  def get_presigned_url(_parent, _args, _context), do: @not_authenticated

  @doc """
  Add attachment
  """
  def add_attachment(_parent, %{attachment_input: attrs}, %{
        context: %{current_user: current_user}
      }) do
    EctoHelpers.action_wrapped(fn ->
      attrs = Map.put(attrs, :user_id, current_user.id)
      Attachments.add_attachment(attrs)
    end)
  end

  def add_attachment(_parent, _args, _context), do: @not_authenticated

  def get_attachment(_parent, %{attachment_id: attachment_id}, %{
        context: %{current_user: current_user}
      }) do
    attachment = Attachments.get_attachment(attachment_id)
  end

  def get_attachments_by_inspection_id(_parent, %{inspection_id: inspection_id}, %{
        context: %{current_user: current_user}
      }) do
    attachments = Attachments.get_inspection_attachments(inspection_id)
    resp = {:ok, %{attachments: attachments}}
  end

  def get_attachments_by_squawk_id(_parent, %{squawk_id: squawk_id}, %{
        context: %{current_user: current_user}
      }) do
    attachments = Attachments.get_squawk_attachments(squawk_id)
    resp = {:ok, %{attachments: attachments}}
  end

  def get_attachment(_parent, _args, _context), do: @not_authenticated

  def get_attachments(_parent, _args, %{context: %{current_user: current_user}}) do
    attachments = Attachments.get_attachments(current_user.id)
    resp = {:ok, %{attachments: attachments}}
  end

  def get_attachments(_parent, _args, _context), do: @not_authenticated

  def update_attachment(_parent, args, %{context: %{current_user: current_user}}) do
    case Attachments.get_attachment(args.id) do
      nil ->
        @not_found

      attachment ->
        Attachments.update_attachment(attachment, args.attachment_input)
    end
  end

  def update_attachment(_parent, _args, _context), do: @not_authenticated

  def delete_attachment(_parent, %{id: id}, %{context: %{current_user: current_user}}) do
    case Attachments.get_attachment_by_id_and_user_id(id, current_user.id) do
      nil ->
        @not_found

      attachment ->
        case Attachments.delete_attachment(attachment) do
          {:ok, attachment} ->
            {:ok, true}

          {:error, reason} ->
            {:error, false}
        end
    end
  end

  def delete_attachment(_parent, _args, _context), do: @not_authenticated
end

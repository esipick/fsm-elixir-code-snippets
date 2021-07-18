defmodule FsmWeb.GraphQL.Attachments.AttachmentsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Attachments.AttachmentsResolvers

  enum(:document_type, values: [:pilot, :aircraft])
  enum(:attachment_type, values: [:inspection, :document, :squawk])

  object :attachments_queries do
    @desc "Get Attachment"
    field :get_attachment, :attachment do
      arg(:id, non_null(:id))
      resolve(&AttachmentsResolvers.get_attachment/3)
    end

    @desc "Get Attachments by user"
    field :get_attachments, :attachment_data do
      resolve(&AttachmentsResolvers.get_attachments/3)
    end

    @desc "Get Attachments by inspection id"
    field :get_attachments, :attachment_data do
      arg(:inspection_id, non_null(:id))
      resolve(&AttachmentsResolvers.get_attachments_by_inspection_id/3)
    end

    @desc "Get Attachments by squawk id"
    field :get_attachments, :attachment_data do
      arg(:squawk_id, non_null(:id))
      resolve(&AttachmentsResolvers.get_attachments_by_squawk_id/3)
    end

  end

  object :attachments_mutations do
    @desc "Create presigned url"
    field :gen_presigned_url, :string do
      arg(:resource_id, non_null(:id))
      arg(:file_ext, non_null(:string))
      resolve(&AttachmentsResolvers.get_presigned_url/3)
    end

    @desc "Add attachment"
    field :add_attachment, :attachment do
      arg(:attachment_input, :attachment_input)
      resolve(&AttachmentsResolvers.add_attachment/3)
    end

    @desc "Update attachment"
    field :update_attachment, :attachment do
      arg(:id, non_null(:id))
      arg(:attachment_input, non_null(:attachment_input))
      resolve(&AttachmentsResolvers.update_attachment/3)
    end

    @desc "Delete attachment"
    field :delete_attachment, :boolean do
      arg(:id, non_null(:id))
      resolve(&AttachmentsResolvers.delete_attachment/3)
    end
  end

  object :attachment do
    field(:id, :integer)
    field(:url, :string)
    field(:file_name, :string)
    field(:file_extension, :string)
    field(:size_in_bytes, :integer)
    field(:size_in_bytes, :integer)
    field(:document_type, :document_type)
    field(:attachment_type, :attachment_type)
    field(:expiration_date, :naive_datetime)
  end

  input_object :attachment_input do
    field(:file_name, :string)
    field(:expiration_date, :naive_datetime)
  end

  object :attachment_data do
    field :attachments, list_of(:attachment)
  end

end

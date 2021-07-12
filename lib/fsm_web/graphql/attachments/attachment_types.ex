defmodule FsmWeb.GraphQL.Attachments.AttachmentsTypes do
  use Absinthe.Schema.Notation

  alias FsmWeb.GraphQL.Attachments.AttachmentsResolvers

  object :attachments_queries do
  end

  object :attachments_mutations do
    @desc "Create presigned url"
    field :gen_presigned_url, :string do
      arg(:inspection_id, non_null(:id))
      arg(:file_ext, non_null(:string))
      resolve(&AttachmentsResolvers.get_presigned_url/3)
    end
  end
end
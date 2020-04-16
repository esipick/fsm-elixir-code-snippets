defmodule Flight.DocumentUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  # @versions [:original, :thumb]
  # @extension_whitelist ~w(.jpg .jpeg .gif .png)

  # def acl(:original, _), do: :public_read

  # def formats, do: @extension_whitelist

  # def validate({file, _}) do
  #   Path.extname(file.file_name) in @extension_whitelist
  # end

  def storage_dir(_version, {_file, scope}) do
    "uploads/#{Mix.env()}/user/#{scope.user_id}/documents/#{scope.id}"
  end
end

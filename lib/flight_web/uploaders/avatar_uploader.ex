defmodule Flight.AvatarUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original, :thumb]
  @extension_whitelist ~w(.jpg .jpeg .gif .png)

  def acl(:thumb, _), do: :public_read

  def validate({file, _}) do
    Enum.member?(@extension_whitelist, Path.extname(file.file_name))
  end

  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  end

  def storage_dir(version, {_file, _scope}) do
    "uploads/#{Mix.env()}/user/avatars/#{version}"
  end
end

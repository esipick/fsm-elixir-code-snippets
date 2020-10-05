defmodule Flight.AircraftMaintenanceUploader do
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
      "uploads/#{Mix.env()}/aircraft_maintenance/#{scope.aircraft_maintenance_id}"
    end
  
    def s3_object_headers(_version, {file, _scope}) do
      [content_type: MIME.from_path(file.file_name)]
    end
  end
  
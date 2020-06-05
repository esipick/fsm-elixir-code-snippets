defmodule ValidationUtil do
  import Ecto.Changeset

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def validate_required_if(changeset, field, condition_field) do
    if get_field(changeset, condition_field) do
      validate_field_presence(changeset, field)
    else
      changeset
    end
  end

  def validate_required_unless(changeset, field, condition_field) do
    if !get_field(changeset, condition_field) do
      validate_field_presence(changeset, field)
    else
      changeset
    end
  end

  defp present?(changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end

  defp validate_field_presence(changeset, field) do
    if present?(changeset, field) do
      changeset
    else
      add_error(changeset, field, "can't be blank")
    end
  end
end

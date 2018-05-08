defmodule FlightWeb.ViewHelpers do
  def format_date(date) when is_binary(date), do: date
  def format_date(nil), do: ""

  def format_date(date) do
    Flight.Date.format(date)
  end

  def human_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn _, _, {message, _} ->
      message
    end)
    |> Enum.reduce([], fn {key, message_list}, acc ->
      Enum.map(message_list, fn message ->
        "#{Phoenix.Naming.humanize(human_key_transform(key))} #{message}"
      end) ++ acc
    end)
  end

  def human_key_transform(key) do
    case key do
      :medical_expires_at -> :medical_expiration
      other -> other
    end
  end
end

defmodule Flight.Format do
  def phone_number_regex do
    ~r/^\(?([0-9]{3})\)?[-.● ]?([0-9]{3})[-.● ]?([0-9]{4})$/
  end

  def normalize_phone_number(number) do
    case Regex.run(phone_number_regex(), number) do
      [_, first, second, third] ->
        {:ok, "#{first}-#{second}-#{third}"}

      _ ->
        {:error, :invalid_format}
    end
  end

  def display_phone_number(nil), do: "—"

  def display_phone_number(phone_number) do
    case Regex.run(phone_number_regex(), phone_number) do
      [_, first, second, third] -> "(#{first}) #{second}-#{third}"
      _ -> phone_number
    end
  end

  def tenths_from_hours(hours) do
    (hours * 10) |> trunc()
  end

  def hours_from_tenths(tenths) do
    tenths / 10
  end

  def cents_from_dollars(dollars) do
    (dollars * 100) |> trunc()
  end

  def dollars_from_cents(cents) do
    cents / 100
  end
end

defmodule Flight.Format do
  def phone_number_regex do
    ~r/^\(?([0-9]{3})\)?[-.● ]?([0-9]{3})[-.● ]?([0-9]{4})$/
  end

  def display_phone_number(nil), do: "-"

  def display_phone_number(phone_number) do
    case Regex.run(phone_number_regex(), phone_number) do
      [_, first, second, third] -> "(#{first}) #{second}-#{third}"
      _ -> phone_number
    end
  end
end

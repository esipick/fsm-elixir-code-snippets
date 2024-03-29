defmodule Flight.Format do
  def phone_number_regex do
    ~r/^\(?([0-9]{3})\)?[-.● ]?([0-9]{3})[-.● ]?([0-9]{4})$/
  end

  def zipcode_regex do
    ~r/^[0-9]{5}(?:-[0-9]{4})?$/
  end

  def ftn_regex do
    ~r/^[A-Z][0-9]+$/
  end

  def serial_number_regex do
    ~r/^([0-9]{5})|([0-9]{2}-[0-9]{5})$/
  end

  def tail_number_regex do
    ~r/^N[1-9]((\d{0,4})|(\d{0,3}[A-HJ-NP-Z])|(\d{0,2}[A-HJ-NP-Z]{2}))$/
  end

  def email_regex do
    ~r/^[a-z0-9](\.?[\w.!#$%&’*+\-\/=?\^`{|}~]){0,}@[a-z0-9-]+\.([a-z]{1,6}\.)?[a-z]{2,6}$/i
#    ~r/^[\w.!#$%&’*+\-\/=?\^`{|}~]+@([a-zA-Z0-9-]+)\.([a-zA-Z0-9-]+)*$/i
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

  def currency(amount) do
    CurrencyFormatter.format(amount, "USD", keep_decimals: true)
  end

  def currency(amount, :short) do
    CurrencyFormatter.format(amount, "USD", keep_decimals: false)
  end

  def tenths_from_hours(nil) do
    0
  end

  def tenths_from_hours(hours) do
    (hours * 10) |> trunc()
  end

  def hours_from_tenths(nil) do
    0
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

defmodule Flight.Currency do
  def cents_from_dollars!(dollars) do
    {:ok, cents} = cents_from_dollars(dollars)
    cents
  end

  def cents_from_dollars(dollars) when is_binary(dollars) do
    with {float, ""} <- Float.parse(dollars) do
      cents_from_dollars(float)
    else
      _ -> {:error, :invalid}
    end
  end

  def cents_from_dollars(dollars) when is_number(dollars) do
    {:ok, (dollars * 100) |> trunc()}
  end

  def dollars_from_cents!(cents) do
    {:ok, dollars} = dollars_from_cents(cents)
    dollars
  end

  def dollars_from_cents(cents) when is_binary(cents) do
    with {float, ""} <- Float.parse(cents) do
      dollars_from_cents(float)
    else
      _ -> {:error, :invalid}
    end
  end

  def dollars_from_cents(cents) when is_number(cents) do
    {:ok, (cents / 100) |> trunc()}
  end
end

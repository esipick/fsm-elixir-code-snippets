defmodule Flight.Date do
  @behaviour Ecto.Type
  def type, do: :date

  def cast(string) when is_binary(string) do
    case Timex.parse(string, "{M}/{D}/{0YYYY}") do
      {:ok, %NaiveDateTime{year: y, month: m, day: d}} -> Date.new(y, m, d)
      {:error, _} -> Ecto.Type.cast(:date, string)
    end
  end

  def cast(date), do: Ecto.Type.cast(:date, date)
  def load(data), do: Ecto.Type.load(:date, data)
  def dump(date), do: Ecto.Type.dump(:date, date)

  def format(date) do
    Timex.format!(date, "{M}/{D}/{YYYY}")
  end
end

defmodule Flight.HourTenth do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} ->
        {:ok, Flight.Format.tenths_from_hours(float)}

      _ ->
        Ecto.Type.cast(:integer, string)
    end
  end

  def cast(date), do: Ecto.Type.cast(:integer, date)
  def load(data), do: Ecto.Type.load(:integer, data)
  def dump(date), do: Ecto.Type.dump(:integer, date)
end

defmodule Flight.DollarCents do
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} ->
        {:ok, Flight.Format.cents_from_dollars(float)}

      _ ->
        Ecto.Type.cast(:integer, string)
    end
  end

  def cast(date), do: Ecto.Type.cast(:integer, date)
  def load(data), do: Ecto.Type.load(:integer, data)
  def dump(date), do: Ecto.Type.dump(:integer, date)
end

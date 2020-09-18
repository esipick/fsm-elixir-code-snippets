defmodule Flight.Date do
  use Ecto.Type
  import Ecto.Type

  def type, do: :date

  def cast(string) when is_binary(string) do
    case Timex.parse(string, "{M}/{D}/{0YYYY}") do
      {:ok, %NaiveDateTime{year: y, month: m, day: d}} -> Date.new(y, m, d)
      {:error, _} -> cast(:date, string)
    end
  end

  def cast(date), do: cast(:date, date)
  def load(data), do: load(:date, data)
  def dump(date), do: dump(:date, date)

  def format(date) do
    Timex.format!(date, "{M}/{D}/{YYYY}")
  end

  def standard_format(date) do
    Timex.format!(date, "%d/%m/%Y", :strftime)
  end

  def html5_format(date) do
    Timex.format!(date, "%Y-%m-%d", :strftime)
  end
end

defmodule Flight.HourTenth do
  use Ecto.Type
  import Ecto.Type

  def type, do: :integer

  def cast(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} ->
        {:ok, Flight.Format.tenths_from_hours(float)}

      _ ->
        cast(:integer, string)
    end
  end

  def cast(date), do: cast(:integer, date)
  def load(data), do: load(:integer, data)
  def dump(date), do: dump(:integer, date)
end

defmodule Flight.DollarCents do
  use Ecto.Type
  import Ecto.Type

  def type, do: :integer

  def cast(string) when is_binary(string) do
    case Float.parse(string) do
      {float, ""} ->
        {:ok, Flight.Format.cents_from_dollars(float)}

      _ ->
        cast(:integer, string)
    end
  end

  def cast(date), do: cast(:integer, date)
  def load(data), do: load(:integer, data)
  def dump(date), do: dump(:integer, date)
end

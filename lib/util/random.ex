defmodule Flight.Random do
  def string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  @hex_values ["a", "b", "c", "d", "e", "f", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

  def hex(length) do
    Enum.reduce(0..(length - 1), "", fn _, acc -> acc <> Enum.random(@hex_values) end)
  end
end

defmodule HobbsTachUtil do
  def coerce_hobbs_tach_time(attrs) do
    attrs
    |> coerce_hobbs_tach_time_value(:hobbs_start)
    |> coerce_hobbs_tach_time_value(:hobbs_end)
    |> coerce_hobbs_tach_time_value(:tach_start)
    |> coerce_hobbs_tach_time_value(:tach_end)
  end

  def coerce_hobbs_tach_time_value(struct, key) do
    case Map.get(struct, key) do
      nil -> struct
      change -> Map.put(struct, key, round(change))
    end
  end
end

defmodule Optional do
  def map(value_or_nil, func) do
    if value_or_nil do
      func.(value_or_nil)
    else
      nil
    end
  end
end

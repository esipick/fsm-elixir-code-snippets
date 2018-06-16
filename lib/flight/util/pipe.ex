defmodule Pipe do
  def pass_unless(item, conditional, func) do
    if conditional do
      func.(item)
    else
      item
    end
  end
end

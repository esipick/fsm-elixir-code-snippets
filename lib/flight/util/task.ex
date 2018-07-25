defmodule Mondo.Task do
  def start(func) do
    if Mix.env() == :test do
      func.()
    else
      Task.start(fn ->
        func.()
      end)
    end
  end
end

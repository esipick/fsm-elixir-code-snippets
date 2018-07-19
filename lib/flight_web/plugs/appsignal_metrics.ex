defmodule AppsignalNamespace do
  def init(_), do: nil

  def call(%Plug.Conn{} = conn, _) do
    Appsignal.Transaction.set_namespace("admin")
    conn
  end
end

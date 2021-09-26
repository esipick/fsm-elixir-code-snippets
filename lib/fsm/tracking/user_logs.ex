defmodule Fsm.Tracking.UserLogs do
  @moduledoc false
  import Ecto.Query, warn: false
  alias Fsm.Tracking.UserLog
  alias Flight.Repo

  @doc false
  def store(log) do
    log = %UserLog{}
    |> UserLog.changeset(log)
    |> Repo.insert()

    log = case log do
      {:ok, result} ->
        {:ok, result}
      {:error, changeset} ->
        {:error, "unable to create user log"}
    end
  end
end

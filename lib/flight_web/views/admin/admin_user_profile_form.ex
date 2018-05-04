defmodule FlightWeb.Admin.UserProfileForm do
  import Ecto.Changeset

  @schema %{
    first_name: :string,
    last_name: :string,
    email: :string,
    roles: :list,
    phone_number: :string,
    address_1: :string,
    city: :string,
    state: :string,
    zipcode: :string,
    flight_training_number: :string,
    medical_rating: :string,
    medical_expires_at: :date,
    certificates: :list,
    certificate_number: :string,
    billing_rate: :integer,
    pay_rate: :integer
  }

  def new do
    # we could pre-fill with default values here
    cast(%{})
  end

  def submit(params) do
    case process_params(params) do
      {:ok, data} ->
        IO.inspect("New message from #{data.full_name}:")
        IO.inspect(data.message)
        :ok

      error ->
        error
    end
  end

  defp validate(changeset) do
    changeset
    |> validate_required([:first_name, :last_name, :email])
    |> validate_inclusion(:medical_rating, 0..3)
    |> validate_acceptance(:accept_tos)
  end

  defp process_params(params) do
    params
    |> cast()
    |> validate()
    |> apply_action(:insert)
  end

  defp cast(params) do
    data = %{}
    empty_map = Map.keys(@schema) |> Enum.reduce(%{}, fn key, acc -> Map.put(acc, key, nil) end)

    changeset = {data, @schema} |> Ecto.Changeset.cast(params, Map.keys(@schema))

    put_in(changeset.changes, Map.merge(empty_map, changeset.changes))
  end
end

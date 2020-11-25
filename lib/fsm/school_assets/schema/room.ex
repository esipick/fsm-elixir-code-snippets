defmodule Fsm.SchoolAssets.Room do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Flight.Repo
  alias Flight.SchoolScope

  schema "rooms" do
    field(:capacity, :integer)
    field(:location, :string)
    field(:block_rate_per_hour, Flight.DollarCents)
    field(:rate_per_hour, Flight.DollarCents)
    field(:resources, :string)
    field(:archived, :boolean, default: false)

    belongs_to(:school, Flight.Accounts.School)

    timestamps()
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :capacity,
      :location,
      :resources,
      :rate_per_hour,
      :block_rate_per_hour,
      :school_id
    ])
    |> validate_required([
      :capacity,
      :location,
      :resources,
      :rate_per_hour,
      :block_rate_per_hour,
      :school_id
    ])
    |> validate_number(:rate_per_hour, greater_than_or_equal_to: 0, less_than: 2147483600, message: "(Rate per hour) must be between $0 and $21474835")
    |> validate_number(:block_rate_per_hour, greater_than_or_equal_to: 0, less_than: 2147483600, message: "(Block rate per hour) must be between $0 and $21474835")
  end

#  def update(room, attrs) do
#    room
#    |> changeset(attrs)
#    |> Repo.update()
#  end

#  def create(attrs, school_context) do
#    %Room{}
#    |> SchoolScope.school_changeset(school_context)
#    |> Room.changeset(attrs)
#    |> Repo.insert()
#  end
#
#  def archive!(%Room{} = room) do
#    if !room.archived do
#      change(room, %{archived: true}) |> Repo.update()
#    end
#  end
end

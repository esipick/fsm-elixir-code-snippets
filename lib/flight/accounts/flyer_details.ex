defmodule Flight.Accounts.FlyerDetails do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flyer_details" do
    field(:address_1, :string)
    field(:city, :string)
    field(:faa_tracking_number, :string)
    field(:state, :string)
    belongs_to(:user, Flight.Accounts.User)

    timestamps()
  end

  @doc false
  def changeset(flyer_details, attrs) do
    flyer_details
    |> cast(attrs, [:address_1, :city, :state, :faa_tracking_number])
    |> validate_required([:address_1, :city, :state, :faa_tracking_number])
  end

  def default() do
    %Flight.Accounts.FlyerDetails{
      address_1: "",
      city: "",
      faa_tracking_number: "",
      state: ""
    }
  end

  def student_keys() do
    [:address_1, :city, :state, :faa_tracking_number]
  end

  def instructor_keys() do
    [:address_1, :city, :state, :faa_tracking_number]
  end

  def renter_keys() do
    [:address_1, :city, :state, :faa_tracking_number]
  end

  def admin_keys() do
    []
  end
end

defmodule Flight.Accounts.SchoolOnboarding do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Flight.Repo

  schema "school_onboardings" do
    field(:completed, :boolean, defalt: false)
    field(:current_step, SchoolOnboardingCurrentStepEnum, default: :school)

    belongs_to(:school, Flight.Accounts.School)

    timestamps()
  end

  def create(attrs) do
    SchoolOnboarding.changeset(%SchoolOnboarding{}, attrs) |> Repo.insert()
  end

  def update(school_onboarding, attrs) do
    school_onboarding
    |> changeset(attrs)
    |> Repo.update()
  end

  def changeset(%SchoolOnboarding{} = school_onboarding, attrs) do
    school_onboarding
    |> cast(attrs, [:current_step, :completed, :school_id])
    |> assoc_constraint(:school)
  end
end

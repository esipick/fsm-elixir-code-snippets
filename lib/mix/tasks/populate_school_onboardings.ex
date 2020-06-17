defmodule Mix.Tasks.PopulateSchoolOnboardings do
  use Mix.Task

  alias Flight.Repo
  alias Flight.Accounts.{School, SchoolOnboarding}

  @shortdoc "Creates onboardings for schools"
  def run(_) do
    [:postgrex, :ecto, :tzdata]
    |> Enum.each(&Application.ensure_all_started/1)

    Repo.start_link()

    IO.puts("Get schools")

    schools = Repo.all(School)

    for school <- schools do
      IO.puts("Read school with id #{school.id}")

      case SchoolOnboarding.create(%{school_id: school.id}) do
        {:ok, school_onboarding} ->
          IO.puts("Onboarding with id #{school_onboarding.id} created")

        {:error, error} ->
          IO.puts("Can't create onboarding for school with id: #{school.id}. Error: #{error}")
      end
    end

    IO.puts("Task completed successfully.")
  end
end

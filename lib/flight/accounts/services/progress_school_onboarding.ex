defmodule Flight.Accounts.ProgressSchoolOnboarding do
  import Flight.OnboardingUtil

  alias Flight.Accounts.{School, SchoolOnboarding}

  def run(school, %{redirect_tab: redirect_tab}) do
    if onboarding_completed?(school) do
      {school, redirect_tab}
    else
      progress_school_onboarding(school, redirect_tab)
    end
  end

  def run(school, %{step_back: "true"}) do
    current_step = current_step(school)
    previous_step = get_position(current_step) - 1

    if previous_step < 0 do
      {school, current_step}
    else
      attrs = %{current_step: previous_step}
      update_school_onboarding(school, attrs, current_step)
    end
  end

  def progress_school_onboarding(school, redirect_tab) do
    current_step = current_step(school)
    next_step = get_position(current_step) + 1

    attrs =
      if next_step > steps_length() - 1 do
        %{completed: true}
      else
        %{current_step: next_step}
      end

    update_school_onboarding(school, attrs, redirect_tab)
  end

  def update_school_onboarding(school, attrs, redirect_tab) do
    case SchoolOnboarding.update(school.school_onboarding, attrs) do
      {:ok, school_onboarding} ->
        school = %{school | school_onboarding: school_onboarding}
        {school, school_onboarding.current_step}

      {:error, _changeset} ->
        {school, redirect_tab}
    end
  end
end

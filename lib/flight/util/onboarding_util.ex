defmodule Flight.OnboardingUtil do
  @steps SchoolOnboardingCurrentStepEnum.__enum_map__()

  def steps_length do
    length(@steps)
  end

  def get_position(step) do
    @steps[step]
  end

  def current_step(school) do
    school.school_onboarding.current_step
  end

  def onboarding_completed?(school) do
    school.school_onboarding.completed
  end
end

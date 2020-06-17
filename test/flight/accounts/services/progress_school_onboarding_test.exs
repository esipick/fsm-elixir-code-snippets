defmodule Flight.Accounts.ProgressSchoolOnboardingTest do
  use Flight.DataCase

  alias Flight.Accounts.ProgressSchoolOnboarding

  describe "run/2 with redirect_tab" do
    test "move onboarding to next step" do
      school_onboarding = school_onboarding_fixture(%{current_step: :contact})
      school = school_onboarding.school

      {_school, tab} = ProgressSchoolOnboarding.run(school, %{redirect_tab: "contact"})
      school_onboarding = refresh(school_onboarding)

      assert tab == :payment
      assert school_onboarding.completed == false
      assert school_onboarding.current_step == :payment
    end
  end

  describe "run/2 with redirect_tab when onboarding was completed" do
    test "returns redirect tab and school" do
      school_onboarding = completed_school_onboarding_fixture()
      school = school_onboarding.school

      {_school, tab} = ProgressSchoolOnboarding.run(school, %{redirect_tab: "payment"})
      school_onboarding = refresh(school_onboarding)

      assert tab == :payment
      assert school_onboarding.completed == true
      assert school_onboarding.current_step == :assets
    end
  end

  describe "run/2 with redirect_tab when onboarding is at last step" do
    test "completes onboarding" do
      school_onboarding = school_onboarding_fixture(%{current_step: :assets})
      school = school_onboarding.school

      {_school, tab} = ProgressSchoolOnboarding.run(school, %{redirect_tab: "assets"})
      school_onboarding = refresh(school_onboarding)

      assert tab == :assets
      assert school_onboarding.completed == true
      assert school_onboarding.current_step == :assets
    end
  end

  describe "run/2 with step_back" do
    test "move onboarding to previous step" do
      school_onboarding = school_onboarding_fixture(%{current_step: :payment})
      school = school_onboarding.school

      {_school, tab} = ProgressSchoolOnboarding.run(school, %{step_back: "true"})
      school_onboarding = refresh(school_onboarding)

      assert tab == :contact
      assert school_onboarding.completed == false
      assert school_onboarding.current_step == :contact
    end
  end

  describe "run/2 with step_back when onboarding is at first step" do
    test "returns onboarding current step" do
      school_onboarding = school_onboarding_fixture()
      school = school_onboarding.school

      {_school, tab} = ProgressSchoolOnboarding.run(school, %{step_back: "true"})
      school_onboarding = refresh(school_onboarding)

      assert tab == :school
      assert school_onboarding.completed == false
      assert school_onboarding.current_step == :school
    end
  end
end

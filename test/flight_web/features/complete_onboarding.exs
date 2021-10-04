defmodule FlightWeb.Features.CompleteOnboardingTest do
  use FlightWeb.FeatureCase, async: true

  @tag :integration
  test "admin doesn't have access to any pages", %{session: session} do
    school_onboarding = school_onboarding_fixture(%{current_step: :contact})
    school = school_onboarding.school

    session
    |> log_in_admin(school)
    |> visit("/admin/dashboard")
    |> assert_has(css(".nav-link.onboarding.completed", text: " DETAILS"))
    |> assert_has(css(".nav-link.onboarding.active", text: "USER ROLES"))
    |> assert_has(css(".nav-link.onboarding.upcoming", text: "PROFILE SETTINGS"))
  end

  @tag :integration
  test "admin completes onboarding", %{session: session} do
    school_onboarding = school_onboarding_fixture()
    school = school_onboarding.school

    session
    |> log_in_admin(school)
    |> assert_has(css(".nav-link.onboarding.active", text: "SCHOOL DETAILS"))
    |> click(button("Save & Next"))
    |> assert_has(css(".nav-link.onboarding.active", text: "USER ROLES"))
    |> click(button("Save & Next"))
    |> assert_has(css(".nav-link.onboarding.active", text: "PROFILE SETTINGS"))
    |> click(button("Save & Next"))
    |> assert_has(css(".nav-link.onboarding.active", text: "RESOURCES"))
    |> click(button("Save & Next"))
    |> assert_has(css(".nav-link.onboarding.active", text: "PAYMENT SETUP"))
    |> click(link("Save & Next"))
    |> assert_has(css(".nav-link.onboarding.active", text: "BILLING SETTINGS"))
    |> click(link("Complete"))
    |> assert_has(css(".stats-title", text: "STUDENTS"))
  end

  @tag :integration
  test "admin can return in steps", %{session: session} do
    school_onboarding = school_onboarding_fixture(%{current_step: :resources})
    school = school_onboarding.school

    session
    |> log_in_admin(school)
    |> assert_has(css(".nav-link.onboarding.active", text: "BILLING SETTINGS"))
    |> click(link("Back"))
    |> assert_has(css(".nav-link.onboarding.active", text: "PAYMENTS"))
    |> click(link("Back"))
    |> assert_has(css(".nav-link.onboarding.active", text: "RESOURCES"))
    |> click(link("Back"))
    |> assert_has(css(".nav-link.onboarding.active", text: "PROFILE SETTINGS"))
    |> click(link("Back"))
    |> assert_has(css(".nav-link.onboarding.active", text: "USER ROLES"))
    |> click(link("Back"))
    |> assert_has(css(".nav-link.onboarding.active", text: "SCHOOL DETAILS"))
  end
end

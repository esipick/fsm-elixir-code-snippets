defmodule FlightWeb.FeatureHelpers do
  import Flight.AccountsFixtures
  import Wallaby.Browser
  import Wallaby.Query

  def log_in_student(session, attrs \\ %{email: "student@example.com", password: "password"}) do
    student_fixture(attrs)

    session
    |> visit("/login")
    |> fill_in(text_field("Email"), with: attrs.email)
    |> fill_in(text_field("Password"), with: attrs.password)
    |> click(button("Login"))
  end

  def log_in_admin(session, attrs \\ %{email: "admin@example.com", password: "password"}) do
    admin_fixture(attrs)

    session
    |> visit("/login")
    |> fill_in(text_field("Email"), with: attrs.email)
    |> fill_in(text_field("Password"), with: attrs.password)
    |> click(button("Login"))
  end
end

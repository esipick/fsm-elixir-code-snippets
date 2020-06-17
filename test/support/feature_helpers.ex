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

  def log_in_admin(
        session,
        school \\ default_school_fixture(),
        attrs \\ %{email: "admin@example.com", password: "password"}
      ) do
    admin_fixture(attrs, school)

    session
    |> visit("/login")
    |> fill_in(text_field("Email"), with: attrs.email)
    |> fill_in(text_field("Password"), with: attrs.password)
    |> click(button("Login"))
  end

  def modal_box(msg), do: css(".balance-warning-dialog__content", text: msg)

  def accept_modal(session),
    do: session |> click(css(".balance-warning-dialog__controls > .btn-primary"))

  def dismiss_modal(session),
    do: session |> click(css(".balance-warning-dialog__controls > .btn-danger"))

  def react_select(session, select_id, option_name) do
    session
    |> click(css(select_id))
    |> click(css(".react-select__option", text: option_name))
  end
end

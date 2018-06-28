defmodule Flight.BillingFixtures do
  alias Flight.Repo

  import Flight.AccountsFixtures
  import Flight.SchedulingFixtures

  @hobbs_start 12200
  @hobbs_end 12232
  @tach_start 33333
  @tach_end 33369

  @instructor_hours 23

  alias Flight.Billing.{Transaction}

  def transaction_fixture(
        attrs \\ %{},
        user \\ student_fixture(),
        creator \\ instructor_fixture()
      ) do
    transaction =
      %Transaction{
        state: "pending",
        type: "debit",
        total: 6000,
        user_id: user.id,
        creator_user_id: creator.id
      }
      |> Transaction.changeset(attrs)
      |> Repo.insert!()

    %{transaction | user: user, creator_user: creator}
  end

  def detailed_transaction_form_fixture(
        user \\ student_fixture(),
        creator \\ instructor_fixture(),
        appointment \\ nil,
        aircraft \\ aircraft_fixture(),
        instructor \\ nil
      ) do
    {:ok, form} =
      %FlightWeb.API.DetailedTransactionForm{}
      |> FlightWeb.API.DetailedTransactionForm.changeset(
        detailed_transaction_form_attrs(user, creator, appointment, aircraft, instructor)
      )
      |> Ecto.Changeset.apply_action(:insert)

    form
  end

  def detailed_transaction_form_attrs(
        user \\ student_fixture(),
        creator \\ instructor_fixture(),
        appointment \\ nil,
        aircraft \\ aircraft_fixture(),
        instructor \\ nil
      ) do
    attrs = %{
      user_id: user.id,
      creator_user_id: creator.id,
      appointment_id: Optional.map(appointment, & &1.id)
    }

    attrs =
      if instructor do
        attrs
        |> Map.merge(%{
          instructor_details: %{
            instructor_id: instructor.id,
            hour_tenths: @instructor_hours
          }
        })
      else
        attrs
      end

    if aircraft do
      attrs
      |> Map.merge(%{
        aircraft_details: %{
          aircraft_id: aircraft.id,
          hobbs_start: @hobbs_start,
          hobbs_end: @hobbs_end,
          tach_start: @tach_start,
          tach_end: @tach_end
        }
      })
    else
      attrs
    end
  end

  def custom_transaction_form_attrs(
        attrs \\ %{},
        user \\ student_fixture(),
        creator_user \\ instructor_fixture()
      ) do
    %{
      user_id: user.id,
      creator_user_id: creator_user.id,
      amount: 20000,
      description: "Something",
      source: nil
    }
    |> Map.merge(attrs)
  end

  def custom_transaction_form_fixture(
        attrs \\ %{},
        user \\ student_fixture(),
        creator \\ instructor_fixture()
      ) do
    {:ok, form} =
      %FlightWeb.API.CustomTransactionForm{}
      |> FlightWeb.API.CustomTransactionForm.changeset(
        custom_transaction_form_attrs(attrs, user, creator)
      )
      |> Ecto.Changeset.apply_action(:insert)

    form
  end

  def real_stripe_customer(user) do
    {:ok, customer} = Flight.Billing.create_stripe_customer(user.email)

    user =
      user
      |> Flight.Accounts.User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
      |> Flight.Repo.update!()

    {user, Flight.Billing.create_card(user, "tok_visa") |> elem(1)}
  end
end

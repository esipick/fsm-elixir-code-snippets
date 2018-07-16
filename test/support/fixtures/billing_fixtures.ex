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
        creator \\ instructor_fixture(),
        school \\ default_school_fixture()
      ) do
    transaction =
      %Transaction{
        state: "pending",
        type: "debit",
        total: 6000,
        user_id: user.id,
        creator_user_id: creator.id,
        school_id: school.id
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
    user = Repo.preload(user, school: :stripe_account)

    school =
      if !user.school.stripe_account do
        real_stripe_account(user.school)
      else
        user.school
      end

    {:ok, customer} = Flight.Billing.create_stripe_customer(user.email, school)

    user =
      user
      |> Flight.Accounts.User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
      |> Flight.Repo.update!()

    {%{user | school: school}, Flight.Billing.create_card(user, "tok_visa", school) |> elem(1)}
  end

  def real_stripe_account(school) do
    {:ok, account} = Flight.Billing.create_deferred_stripe_account(school.contact_email)

    school_account =
      Flight.Accounts.StripeAccount.new(account)
      |> Flight.Accounts.StripeAccount.changeset(%{school_id: school.id})
      |> Flight.Repo.insert!()

    %Flight.Accounts.School{school | stripe_account: school_account}
  end

  def api_stripe_account_fixture() do
    {:ok,
     %Stripe.Account{
       business_logo: nil,
       business_name: nil,
       business_url: nil,
       charges_enabled: true,
       country: "US",
       created: nil,
       debit_negative_balances: nil,
       decline_charge_on: nil,
       default_currency: "usd",
       details_submitted: false,
       display_name: nil,
       email: "fsm_local@mailinator.com",
       external_accounts: nil,
       id: "acct_blah",
       legal_entity: nil,
       metadata: %{},
       object: "account",
       payout_schedule: nil,
       payout_statement_descriptor: nil,
       payouts_enabled: false,
       product_description: nil,
       statement_descriptor: "",
       support_email: nil,
       support_phone: nil,
       timezone: "Etc/UTC",
       tos_acceptance: nil,
       transfers_enabled: nil,
       type: "standard",
       verification: nil
     }}
  end
end

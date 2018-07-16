defmodule Flight.Billing.StripeEventsTest do
  use Flight.DataCase

  import Flight.StripeEventsFixtures

  describe "process account.updated" do
    test "changes attributes on school account object" do
      account = stripe_account_fixture()

      refute account.payouts_enabled
      refute account.charges_enabled
      refute account.details_submitted

      event = account_updated_fixture()
      event = put_in(event.data.object.id, account.stripe_account_id)
      event = put_in(event.data.object.details_submitted, true)
      event = put_in(event.data.object.charges_enabled, true)
      event = put_in(event.data.object.payouts_enabled, true)

      Flight.Billing.StripeEvents.process(event)

      account = refresh(account)

      assert account.payouts_enabled
      assert account.charges_enabled
      assert account.details_submitted
    end
  end

  describe "process account.application.deauthorized" do
    test "deletes stripe account" do
      account = stripe_account_fixture()

      event = %{account_application_deauthorized_fixture() | account: account.stripe_account_id}

      Flight.Billing.StripeEvents.process(event)

      refute refresh(account)
    end
  end
end

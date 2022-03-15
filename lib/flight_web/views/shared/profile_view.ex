defmodule FlightWeb.Shared.ProfileView do
  alias Flight.Accounts

  def has_cirriculum?(user) do
    Accounts.has_any_role?(user, ["student"])
  end

  def has_pay_rates?(user) do
    Accounts.has_any_role?(user, ["instructor"])
  end

  def has_teaching_info?(user) do
    Accounts.has_any_role?(user, ["instructor"])
  end

  def has_address?(user) do
    Accounts.has_any_role?(user, ["instructor", "student", "renter", "mechanic"])
  end

  def should_display_address?(user) do
    user.address_1 != nil
  end

  def has_medical?(user) do
    Accounts.has_any_role?(user, ["instructor", "student", "renter", "mechanic"])
  end

  def human_readable_medical_rating(medical_rating) when is_binary(medical_rating) do
    human_readable_medical_rating(String.to_integer(medical_rating))
  end

  def human_readable_medical_rating(medical_rating) when is_integer(medical_rating) do
    case medical_rating do
      0 -> "None"
      1 -> "1st Class"
      2 -> "2nd Class"
      3 -> "3rd Class"
    end
  end

  def medical_rating_exist?(user) do
    user.medical_rating != 0 && user.medical_expires_at
  end

  def human_flyer_certificates(flyer_certificates) do
    result =
      flyer_certificates
      |> Enum.map(&String.upcase(&1.slug))
      |> Enum.join(", ")

    if result == "" do
      "None"
    else
      result
    end
  end

  def human_role(role_slug) do
    String.capitalize(role_slug)
  end

  def fetch_card(user) do
    if user.stripe_customer_id do
      case Stripe.Customer.retrieve(user.stripe_customer_id) do
        {:ok, customer} ->
          Enum.find(customer.sources.data, fn s -> s.id == customer.default_source end)

        _ ->
          nil
      end
    end
  end
end

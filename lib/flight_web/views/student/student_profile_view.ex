defmodule FlightWeb.Student.ProfileView do
  use FlightWeb, :view
  import FlightWeb.ViewHelpers

  alias Flight.Accounts

  def has_cirriculum?(user) do
    Accounts.has_any_role?(user, ["student"])
  end

  def has_address?(user) do
    Accounts.has_any_role?(user, ["instructor", "student", "renter"])
  end

  def should_display_address?(user) do
    user.address_1 != nil
  end

  def has_medical?(user) do
    Accounts.has_any_role?(user, ["instructor", "student"])
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
end

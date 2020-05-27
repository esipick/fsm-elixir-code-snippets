defmodule Flight.Auth.InvoicePolicy do
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  def modify?(user, invoice) do
    case invoice do
      nil ->
        create?(user)

      _ ->
        invoice.status == :pending && view?(user, invoice)
    end
  end

  def create?(_user) do
    true
  end

  def view?(user, invoice) do
    user.id == invoice.user_id || staff_member?(user)
  end

  def can_see_link_to_profile?(user) do
    user_can?(user, [
      Permission.new(:users, :modify, :all),
      Permission.new(:aircraft, :modify, :all)
    ])
  end
end

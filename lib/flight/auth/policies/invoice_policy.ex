defmodule Flight.Auth.InvoicePolicy do
  alias Flight.Auth.Permission
  import Flight.Auth.Authorization

  def modify?(user, invoice) do
    case invoice do
      nil ->
        create?(user)

      _ ->
        invoice.status == :pending && create?(user)
    end
  end

  def create?(user) do
    user_can?(user, [Permission.new(:invoice, :modify, :all)])
  end

  def view?(user, invoice) do
    user.id == invoice.user_id || create?(user)
  end

  def can_see_link_to_profile?(user) do
    user_can?(user, [Permission.new(:users, :modify, :all), Permission.new(:aircraft, :modify, :all)])
  end
end

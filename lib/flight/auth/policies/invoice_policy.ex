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

  def send_invoice?(user, invoice) do
    case invoice do
      nil ->
        false
      _ -> 
        invoice.status == :paid && staff_member?(user)
    end
  end

  def can_send_bulk_invoice?(user) do
    staff_member?(user)
  end

  def delete?(user, invoice) do
    invoice.status != :archived && ( (invoice.status == :pending && staff_member?(user)) || is_admin?(user))
  end

  def can_see_link_to_profile?(user) do
    user_can?(user, [
      Permission.new(:users, :modify, :all),
      Permission.new(:aircraft, :modify, :all)
    ])
  end
end

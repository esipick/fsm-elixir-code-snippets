defmodule Flight.Auth.Permission do
  @moduledoc """
  All Permission structs should follow this naming convention

  > resource_verb_scope

  Available Verbs:
  - view: Able to request a resource, but not edit/create/delete
  - modify: Able to edit/create/delete

  Available Scopes:
  - all: all of the specified resources
  - personal: only the resources owned/associated with the requesting user
  """

  defstruct [:resource, :verb, :scope]

  @resources [
    :admins,
    :aircraft,
    :appointment,
    :appointment_instructor,
    :appointment_student,
    :appointment_user,
    :documents,
    :invoice,
    :invoice_custom_line_items,
    :objective_score,
    :payment_settings,
    :push_token,
    :role,
    :school,
    :transaction,
    :transaction_approve,
    :transaction_cash,
    :transaction_cash_self,
    :transaction_creator,
    :transaction_user,
    :unavailability,
    :unavailability_aircraft,
    :unavailability_instructor,
    :user_protected_info,
    :users,
    :web_dashboard,
    :staff
  ]
  @verbs [:view, :modify, :create, :be, :request, :access]
  @scopes [:all, :personal]

  @doc """
  complex_scope can be of the following forms:

  - :all
  - {:personal, resource}
  """
  def new(resource, verb, complex_scope)
      when verb in @verbs and resource in @resources do
    %Flight.Auth.Permission{
      resource: resource,
      verb: verb,
      scope: complex_scope
    }
  end

  def permission_slug(%Flight.Auth.Permission{} = permission) do
    simple_scope =
      case permission.scope do
        :all -> :all
        {:personal, _} -> :personal
      end

    permission_slug(permission.resource, permission.verb, simple_scope)
  end

  def permission_slug(resource, verb, simple_scope)
      when verb in @verbs and resource in @resources and simple_scope in @scopes do
    "#{resource}:#{verb}:#{simple_scope}"
  end

  def scope_checker(permission, user) do
    case permission.scope do
      :all -> true
      {:personal, resource} -> personal_scope_checker(user, permission.resource, resource)
    end
  end

  def personal_scope_checker(_user, _resource_slug, nil), do: false

  # Refactor this to just use user_id universally instead of this dynamic pattern matching
  def personal_scope_checker(user, resource_slug, resource) do
    case {resource_slug, resource} do
      {:users, %Flight.Accounts.User{id: user_id}} ->
        user.id == user_id

      {:objective_score, %Flight.Curriculum.ObjectiveScore{user_id: user_id}} ->
        user.id == user_id

      {_, user_id} when is_integer(user_id) or is_binary(user_id) ->
        "#{user_id}" == "#{user.id}"

      {:invoice, %Flight.Billing.Invoice{user_id: user_id}} ->
        user.id == user_id

      {:school, %Flight.Accounts.School{id: id}} ->
        user.school_id == id

      _ ->
        raise "Unknown resource_slug and resource: #{resource_slug} #{resource}"
    end
  end
end

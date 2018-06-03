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
  @resources [:users, :appointment_user, :appointment_instructor, :appointment_student]
  @verbs [:view, :modify, :be]

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
      when verb in @verbs and resource in @resources and is_atom(simple_scope) do
    "#{resource}:#{verb}:#{simple_scope}"
  end

  def scope_checker(permission, user) do
    case permission.scope do
      :all -> true
      {:personal, resource} -> personal_scope_checker(user, permission.resource, resource)
    end
  end

  def personal_scope_checker(user, resource_slug, resource) when not is_nil(resource) do
    case {resource_slug, resource} do
      {:users, %Flight.Accounts.User{id: user_id}} -> user.id == user_id
      _ -> raise "Unknown resource_slug and resource: #{resource_slug} #{resource}"
    end
  end
end

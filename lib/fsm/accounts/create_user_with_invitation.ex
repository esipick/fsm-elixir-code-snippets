defmodule Fsm.Accounts.CreateUserWithInvitation do
  alias Fsm.Accounts
  alias Flight.Repo
  alias Fsm.SchoolScope
  alias Fsm.Accounts.User
  alias Fsm.Accounts.Invitation

  def run(
        attrs,
        current_user,
        role,
        aircrafts \\ [],
        instructors \\ [],
        requires_stripe_account? \\ true,
        stripe_token \\ nil
      ) do
    main_instructor_id = Map.get(attrs, "main_instructor_id")
    school_context = %{assigns: %{current_user: current_user}, school_id: current_user.school_id}

    with {:ok, user} = payload <-
           create_user(attrs, school_context, requires_stripe_account?, stripe_token),
           %User{} <-
            Accounts.admin_update_user_profile(
              user,
              %{"main_instructor_id" => main_instructor_id},
              [role.slug]
            ) do
      create_invitation_from_user(user, role, school_context)
      payload
    else
      error ->
        error
    end
  end

  def create_user(
        attrs,
        context,
        requires_stripe_account? \\ true,
        stripe_token \\ nil,
        user \\ %User{}
      ) do
    attrs =
      attrs
      |> Poison.encode!()
      |> Poison.decode!()

    changeset = Accounts.user_changeset(user, attrs, context)

    if changeset.valid? do
      if requires_stripe_account? do
        email = Ecto.Changeset.get_field(changeset, :email)

        case Flight.Billing.create_stripe_customer(email, stripe_token) do
          {:ok, customer} ->
            changeset
            |> User.stripe_customer_changeset(%{
              stripe_customer_id: customer.id
            })
            |> save_user(user)

          error ->
            error
        end
      else
        changeset |> save_user(user)
      end
    else
      Ecto.Changeset.apply_action(changeset, :insert)
    end
  end

  def create_invitation_from_user(user, role, school_context) do
    attrs = %{
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      role_id: role.id,
      user_id: user.id,
      phone_number: Map.get(user, :phone_number)
    }

    create_invitation(attrs, school_context, false)
  end

  def create_invitation(attrs, %{assigns: %{current_user: %{id: id, roles: roles ,school_id: school_id}}, school_id: school_id} = school_context, require_uniq? \\ true) do
    phone = Map.get(attrs, :phone_number) || "000-000-0000"

    context = %{context: %{current_user: %{school_id: school_id, id: id}}}
    changeset =
      %Invitation{}
      |> SchoolScope.school_changeset(context)
      |> Invitation.create_changeset(attrs)
    # school =
    #   School
    #   |> Repo.get(SchoolScope.school_id(school_context))
    #   |> Repo.preload(:stripe_account)

    email = Ecto.Changeset.get_field(changeset, :email)

    role_id = Ecto.Changeset.get_field(changeset, :role_id)

    # role =
    #   Repo.get(Accounts.Role, role_id).slug
    #   |> String.capitalize()

    user = Accounts.get_user_by_email(email)

    cond do
      # !school.stripe_account ->
      #   changeset
      #   |> Ecto.Changeset.add_error(
      #     :user,
      #     "#{role} can't be invited unless you've attached a Stripe account. Go to Settings → Billing Setup to attach a Stripe account."
      #   )
      #   |> Ecto.Changeset.apply_action(:insert)

      user && !user.archived && require_uniq? ->
        changeset
        |> Ecto.Changeset.add_error(:user, "Email already exists.")
        |> Ecto.Changeset.apply_action(:insert)

      true ->
        # IO.inspect(attrs, label: "Attributes")
        # role_id = Map.get(attrs, "role_id") || Map.get(attrs, :role_id)
        role = Accounts.get_role(role_id, :id)
        roles = if role, do: [role], else: []

        password = Flight.Random.hex(10)

        params =
          attrs
          |> Map.take([:email, :first_name, :last_name, :school_id, :phone_number])
          |> Map.put(:password, password)
          |> Map.put(:phone_number, phone)
          |> Map.put(:archived, false)

        user = if user, do: Repo.preload(user, :roles), else: %User{}

        user_changeset =
        user
        |> SchoolScope.school_changeset(school_context)
        |> User.create_user_with_role_changeset(params, roles)

        Repo.transaction(fn ->
          with {:ok, user} <- save_user(user_changeset, user),
               {:ok, invitation} <-
                 Repo.insert(Ecto.Changeset.put_change(changeset, :user_id, user.id)) do
                  Accounts.send_invitation_email(invitation)

            invitation
          else
            {:error, error} ->
              Repo.rollback(error)
          end
        end)
    end
  end

  defp save_user(changeset) do
    Repo.insert(changeset)
  end

  defp save_user(changeset, user) do
    if user.id do
      changeset |> Repo.update()
    else
      changeset |> Repo.insert()
    end
  end
end

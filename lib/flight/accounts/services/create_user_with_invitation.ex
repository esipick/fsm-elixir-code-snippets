defmodule Flight.Accounts.CreateUserWithInvitation do
  alias Flight.Accounts
  alias Flight.Repo
  alias Flight.SchoolScope

  alias Flight.Accounts.{
    User,
    Invitation,
    School
  }

  def run(
        attrs,
        school_context,
        role,
        aircrafts \\ [],
        instructors \\ [],
        requires_stripe_account? \\ true,
        stripe_token \\ nil
      ) do
    main_instructor_id = Map.get(attrs, "main_instructor_id")

    with {:ok, user} = payload <-
           create_user(attrs, school_context, requires_stripe_account?, stripe_token),
         {:ok, user} <-
           Accounts.admin_update_user_profile(
             user,
             %{"main_instructor_id" => main_instructor_id},
             [role.slug],
             aircrafts,
             [],
             instructors
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
        school_context,
        requires_stripe_account? \\ true,
        stripe_token \\ nil,
        user \\ %User{}
      ) do
    attrs =
      attrs
      |> Poison.encode!()
      |> Poison.decode!()

    changeset = Accounts.user_changeset(user, attrs, school_context)

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
      user_id: user.id
    }

    create_invitation(attrs, school_context, false)
  end

  def create_invitation(attrs, school_context, require_uniq? \\ true) do
    changeset =
      %Invitation{}
      |> SchoolScope.school_changeset(school_context)
      |> Invitation.create_changeset(attrs)

    school =
      School
      |> Repo.get(SchoolScope.school_id(school_context))
      |> Repo.preload(:stripe_account)

    email = Ecto.Changeset.get_field(changeset, :email)

    role_id = Ecto.Changeset.get_field(changeset, :role_id)

    role =
      Repo.get(Accounts.Role, role_id).slug
      |> String.capitalize()

    user = Accounts.get_user_by_email(email)

    cond do
      !school.stripe_account ->
        changeset
        |> Ecto.Changeset.add_error(
          :user,
          "#{role} can't be invited unless you've attached a Stripe account. Go to Settings → Billing Setup to attach a Stripe account."
        )
        |> Ecto.Changeset.apply_action(:insert)

      user && require_uniq? ->
        changeset
        |> Ecto.Changeset.add_error(:user, "#{role} has already signed up.")
        |> Ecto.Changeset.apply_action(:insert)

      true ->
        case Repo.insert(changeset) do
          {:ok, invitation} = payload ->
          invitation = Map.put(invitation, :school, %{name: Map.get(school, :name) || "Randon Aviation"})
            Accounts.send_invitation_email(invitation)
            payload

          other ->
            other
        end
    end
  end

  defp save_user(changeset, user) do
    if user.id do
      changeset |> Repo.update()
    else
      changeset |> Repo.insert()
    end
  end
end

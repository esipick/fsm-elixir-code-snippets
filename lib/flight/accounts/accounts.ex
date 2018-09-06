defmodule Flight.Accounts do
  import Ecto.Query, warn: false
  alias Flight.Repo

  alias Flight.Accounts.{
    User,
    UserRole,
    Role,
    FlyerCertificate,
    Invitation,
    School,
    SchoolInvitation,
    StripeAccount
  }

  alias Flight.SchoolScope

  require Flight.Accounts.Role

  def get_user(id, school_context) do
    User
    |> SchoolScope.scope_query(school_context)
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def dangerous_get_user(id), do: Repo.get(User, id)

  def get_users(school_context) do
    User
    |> default_users_query(school_context)
    |> Repo.all()
  end

  def get_directory_users_visible_to_user(user) do
    user = Repo.preload(user, :roles)

    roles =
      Enum.reduce(user.roles, MapSet.new(), fn role, acc ->
        MapSet.union(acc, MapSet.new(roles_visible_to(role.slug)))
      end)
      |> MapSet.to_list()
      |> Enum.map(&Atom.to_string/1)

    from(
      u in User,
      distinct: u.id,
      inner_join: r in assoc(u, :roles),
      where: r.slug in ^roles
    )
    |> default_users_query(user)
    |> Repo.all()
  end

  def roles_visible_to("student") do
    [:instructor, :admin]
  end

  def roles_visible_to("instructor") do
    [:student, :instructor, :admin]
  end

  def roles_visible_to("renter") do
    [:admin]
  end

  def roles_visible_to("admin") do
    [:admin, :student, :renter, :instructor]
  end

  def get_user_count(role, school_context) do
    from(
      u in User,
      inner_join: r in assoc(u, :roles),
      where: r.id == ^role.id
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def get_user(id, roles, school_context) do
    from(
      u in User,
      inner_join: r in assoc(u, :roles),
      where: r.slug in ^roles,
      where: u.id == ^id
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def get_user_by_email(nil, _), do: nil
  def get_user_by_email("", _), do: nil

  def get_user_by_email(email, school_context) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  # Does not scope by school, use wisely!
  def dangerous_get_user_by_email(email) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> Repo.one()
  end

  def create_user(attrs, school_context, requires_stripe_account? \\ true, stripe_token \\ nil) do
    attrs =
      attrs
      |> Poison.encode!()
      |> Poison.decode!()

    changeset = user_changeset(%User{}, attrs, school_context)

    if changeset.valid? do
      if requires_stripe_account? do
        case Flight.Billing.create_stripe_customer(
               Ecto.Changeset.get_field(changeset, :email),
               stripe_token
             ) do
          {:ok, customer} ->
            changeset
            |> User.stripe_customer_changeset(%{
              stripe_customer_id: customer.id,
              stripe_account_source: "platform"
            })
            |> Repo.insert()

          error ->
            error
        end
      else
        changeset
        |> Repo.insert()
      end
    else
      Ecto.Changeset.apply_action(changeset, :insert)
    end
  end

  def user_changeset(user, attrs, school_context) do
    user
    |> SchoolScope.school_changeset(school_context)
    |> User.create_changeset(attrs)
  end

  def api_update_user_profile(%User{} = user, attrs, flyer_certificates) do
    update_user_profile(
      user,
      attrs,
      nil,
      flyer_certificates,
      &User.api_update_changeset/4
    )
  end

  defp update_user_profile(user, attrs, role_slugs, flyer_certificate_slugs, changeset_func) do
    user = Repo.preload(user, [:roles, :flyer_certificates])

    {valid_roles?, roles} =
      if role_slugs do
        roles = Repo.all(from(r in Role, where: r.slug in ^role_slugs))
        valid_roles? = Enum.count(role_slugs) == Enum.count(roles)
        {valid_roles?, roles}
      else
        {true, nil}
      end

    {valid_certs?, certs} =
      if flyer_certificate_slugs do
        certs = Repo.all(from(c in FlyerCertificate, where: c.slug in ^flyer_certificate_slugs))
        valid_certs? = Enum.count(flyer_certificate_slugs) == Enum.count(certs)
        {valid_certs?, certs}
      else
        {true, nil}
      end

    cond do
      !valid_roles? ->
        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], []),
           :roles,
           "are not all known: #{Enum.join(role_slugs, ", ")}"
         )}

      !valid_certs? ->
        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], []),
           :flyer_certificates,
           "are not all known: #{Enum.join(flyer_certificate_slugs, ", ")}"
         )}

      true ->
        user
        |> changeset_func.(attrs, roles, certs)
        |> Repo.update()
    end
  end

  def admin_update_user_profile(%User{} = user, attrs, role_slugs, flyer_certificate_slugs) do
    update_user_profile(
      user,
      attrs,
      role_slugs,
      flyer_certificate_slugs,
      &User.admin_update_changeset/4
    )
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end

  def set_password(user, password) do
    user
    |> User.update_password_changeset(%{password: password})
    |> Repo.update()
  end

  ###
  # Schools
  ###

  def admin_update_school(%School{} = school, attrs) do
    school
    |> School.admin_changeset(attrs)
    |> Repo.update()
  end

  def get_schools() do
    School
    |> Repo.all()
  end

  def get_school(id) do
    Repo.get(School, id)
  end

  ###
  # Form fields
  ###

  def editable_fields(%Flight.Accounts.User{} = user) do
    user = Flight.Repo.preload(user, :roles)

    user.roles
    |> Enum.map(&editable_fields_for_role_slug(&1.slug))
    |> List.flatten()
    |> MapSet.new()
  end

  def editable_fields_for_role_slug("student") do
    [
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode,
      :flight_training_number,
      :medical_rating,
      :medical_expires_at,
      :certificate_number
    ]
  end

  def editable_fields_for_role_slug("instructor") do
    [
      :email,
      :first_name,
      :last_name,
      :phone_number,
      :address_1,
      :city,
      :state,
      :zipcode,
      :flight_training_number,
      :medical_rating,
      :medical_expires_at,
      :certificate_number,
      :flyer_certificates,
      :awards
    ]
  end

  def editable_fields_for_role_slug("renter") do
    [:email, :first_name, :last_name, :phone_number, :flight_training_number]
  end

  def editable_fields_for_role_slug("admin") do
    [:email, :first_name, :last_name, :phone_number]
  end

  #
  # Role
  #

  def get_role!(id), do: Repo.get!(Role, id)
  def get_role(id), do: Repo.get(Role, id)

  def assign_roles(user, roles) do
    for role <- roles do
      (Repo.get_by(UserRole, user_id: user.id, role_id: role.id) ||
         %UserRole{user_id: user.id, role_id: role.id})
      |> UserRole.changeset(%{})
      |> Repo.insert_or_update!()
    end
  end

  def users_with_role(role, school_context) do
    role
    |> Ecto.assoc(:users)
    |> default_users_query(school_context)
    |> Repo.all()
  end

  def users_with_roles([], _school_context) do
    []
  end

  def users_with_roles(roles, school_context) do
    roles
    |> Ecto.assoc(:users)
    |> default_users_query(school_context)
    |> Repo.all()
  end

  defp default_users_query(query, school_context) do
    from(
      u in query,
      order_by: u.last_name
    )
    |> SchoolScope.scope_query(school_context)
  end

  def has_role?(user, role_slug) do
    user = Repo.preload(user, :roles)

    user.roles
    |> Enum.map(& &1.slug)
    |> Enum.member?(role_slug)
  end

  def has_any_role?(user, role_slugs) do
    user = Repo.preload(user, :roles)

    set =
      user.roles
      |> Enum.map(& &1.slug)
      |> MapSet.new()
      |> MapSet.intersection(MapSet.new(role_slugs))

    !Enum.empty?(set)
  end

  def role_for_slug(slug) do
    Repo.get_by(Role, slug: slug)
  end

  #
  # Certificates
  #

  def flyer_certificates() do
    Repo.all(FlyerCertificate)
  end

  def has_flyer_certificate?(user, cert_slug) do
    user = Repo.preload(user, :flyer_certificates)

    user.flyer_certificates
    |> Enum.map(& &1.slug)
    |> Enum.member?(cert_slug)
  end

  #
  # Invitations
  #

  def get_invitation(id, school_context) do
    Invitation
    |> where([i], i.id == ^id)
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def get_invitation_for_email(email, school_context) do
    Invitation
    |> where([i], i.email == ^String.downcase(email))
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def get_invitation_for_token(token) do
    Invitation
    |> where([i], i.token == ^token)
    |> Repo.one()
  end

  def get_invitation_for_token(token, school_context) do
    Invitation
    |> where([i], i.token == ^token)
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def visible_invitations_with_role(role_slug, school_context) do
    from(
      i in Invitation,
      inner_join: r in assoc(i, :role),
      where: is_nil(i.accepted_at),
      where: r.slug == ^role_slug
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.all()
  end

  def accept_invitation(%Invitation{} = invitation) do
    if !invitation.accepted_at do
      invitation
      |> Invitation.accept_changeset(%{accepted_at: NaiveDateTime.utc_now()})
      |> Repo.update()
    else
      {:error, :already_accepted}
    end
  end

  def create_invitation(attrs, school_context) do
    changeset =
      %Invitation{}
      |> SchoolScope.school_changeset(school_context)
      |> Invitation.create_changeset(attrs)

    school =
      School
      |> Repo.get(SchoolScope.school_id(school_context))
      |> Repo.preload(:stripe_account)

    email = Ecto.Changeset.get_field(changeset, :email)

    user = dangerous_get_user_by_email(email)

    cond do
      !school.stripe_account ->
        changeset
        |> Ecto.Changeset.add_error(
          :user,
          "can't be invited unless you've attached a Stripe account. Go to Settings → Billing Setup to attach a Stripe account."
        )
        |> Ecto.Changeset.apply_action(:insert)

      user ->
        changeset
        |> Ecto.Changeset.add_error(:email, "already exists for another user.")
        |> Ecto.Changeset.apply_action(:insert)

      true ->
        case Repo.insert(changeset) do
          {:ok, invitation} = payload ->
            send_invitation_email(invitation)
            payload

          other ->
            other
        end
    end
  end

  def create_user_from_invitation(user_data, stripe_token, invitation) do
    invitation = Repo.preload(invitation, :school)

    result =
      Repo.transaction(fn ->
        case create_user(user_data, invitation.school, true, stripe_token) do
          {:ok, user} ->
            accept_invitation(invitation)
            role = get_role(invitation.role_id)
            assign_roles(user, [role])

            if role.slug == "student" do
              amount = Application.get_env(:flight, :platform_fee_amount)

              charge_result =
                Stripe.Charge.create(%{
                  amount: amount,
                  currency: "usd",
                  customer: user.stripe_customer_id,
                  description: "Platform fee",
                  receipt_email: user.email
                })

              case charge_result do
                {:ok, charge} ->
                  %Flight.Billing.PlatformCharge{}
                  |> Flight.Billing.PlatformCharge.changeset(%{
                    user_id: user.id,
                    amount: amount,
                    type: "platform_fee",
                    stripe_charge_id: charge.id
                  })
                  |> Repo.insert()

                  user

                {:error, error} ->
                  Repo.rollback(error)
              end
            else
              user
            end

          {:error, error} ->
            Repo.rollback(error)
        end
      end)

    result
  end

  def send_invitation_email(invitation) do
    Flight.Email.invitation_email(invitation)
    |> Flight.Mailer.deliver_later()
  end

  ###
  # School Invitations
  ###

  def get_school_invitation(id) do
    SchoolInvitation
    |> where([i], i.id == ^id)
    |> Repo.one()
  end

  def get_school_invitation_for_email(email) do
    SchoolInvitation
    |> where([i], i.email == ^String.downcase(email))
    |> Repo.one()
  end

  def get_school_invitation_for_token(token) do
    SchoolInvitation
    |> where([i], i.token == ^token)
    |> Repo.one()
  end

  def visible_school_invitations() do
    from(
      i in SchoolInvitation,
      where: is_nil(i.accepted_at)
    )
    |> Repo.all()
  end

  def accept_school_invitation(%SchoolInvitation{} = invitation) do
    if !invitation.accepted_at do
      invitation
      |> SchoolInvitation.accept_changeset(%{accepted_at: NaiveDateTime.utc_now()})
      |> Repo.update()
    else
      {:error, :already_accepted}
    end
  end

  def create_school_invitation(attrs) do
    changeset =
      %SchoolInvitation{}
      |> SchoolInvitation.create_changeset(attrs)

    email = Ecto.Changeset.get_field(changeset, :email)

    user = dangerous_get_user_by_email(email)

    if !user do
      case Repo.insert(changeset) do
        {:ok, invitation} = payload ->
          send_school_invitation_email(invitation)
          payload

        other ->
          other
      end
    else
      changeset
      |> Ecto.Changeset.add_error(:email, "already exists for another user.")
      |> Ecto.Changeset.apply_action(:insert)
    end
  end

  # If an {:error, changeset} tuple is returned, it can be either the changeset for the school or the user
  def create_school_from_invitation(user_data, %SchoolInvitation{} = school_invitation) do
    user_data =
      user_data
      |> Poison.encode!()
      |> Poison.decode!()

    school_data = school_data_from_user_data(user_data)

    school_change =
      %School{}
      |> School.create_changeset(school_data)

    user_change =
      %User{}
      |> User.initial_user_changeset(user_data)

    cond do
      !user_change.valid? ->
        Ecto.Changeset.apply_action(user_change, :insert)

      !school_change.valid? ->
        Ecto.Changeset.apply_action(school_change, :insert)

      true ->
        Repo.transaction(fn ->
          with {:ok, school} <- create_school(school_data),
               {:ok, user} <- create_user(user_data, school, school.stripe_account != nil) do
            accept_school_invitation(school_invitation)
            assign_roles(user, [Role.admin()])

            {school, user}
          else
            {:error, error} ->
              Repo.rollback(error)
          end
        end)
    end
  end

  def send_school_invitation_email(invitation) do
    Flight.Email.school_invitation_email(invitation)
    |> Flight.Mailer.deliver_later()
  end

  def school_data_from_user_data(user_data) do
    %{
      contact_email: user_data["email"],
      contact_phone_number: user_data["phone_number"],
      contact_first_name: user_data["first_name"],
      contact_last_name: user_data["last_name"],
      timezone: user_data["timezone"],
      name: user_data["school_name"]
    }
  end

  def user_data_from_school_data(school, school_data) do
    %{
      email: school.contact_email,
      phone_number: school.contact_phone_number,
      first_name: school.contact_first_name,
      last_name: school.contact_last_name,
      password: school_data[:password] || school_data["password"]
    }
  end

  ###
  # Schools
  ###

  def create_missing_stripe_customers(school_context) do
    users =
      from(u in User, where: is_nil(u.stripe_customer_id))
      |> SchoolScope.scope_query(school_context)
      |> Repo.all()

    for user <- users do
      {:ok, customer} = Flight.Billing.create_stripe_customer(user.email, nil)

      user
      |> User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
      |> Repo.update()
    end
  end

  def fetch_and_create_stripe_account_from_account_id(account_id, school_context) do
    with {:ok, api_account} <- Stripe.Account.retrieve(account_id),
         {:ok, account} <- create_stripe_account(api_account, school_context) do
      create_missing_stripe_customers(school_context)
      {:ok, account}
    else
      error -> error
    end
  end

  def create_stripe_account(%Stripe.Account{} = account, school_context) do
    StripeAccount.new(account)
    |> SchoolScope.school_changeset(school_context)
    |> StripeAccount.changeset(%{})
    |> Repo.insert()
  end

  def create_school(attrs) do
    changeset =
      %School{}
      |> School.create_changeset(attrs)

    if changeset.valid? do
      account =
        case Flight.Billing.create_deferred_stripe_account(
               Ecto.Changeset.get_field(changeset, :contact_email),
               Ecto.Changeset.get_field(changeset, :name)
             ) do
          {:ok, account} ->
            account

          _error ->
            nil
        end

      Repo.transaction(fn ->
        {:ok, school} =
          changeset
          |> Repo.insert()

        stripe_account =
          if account do
            StripeAccount.new(account)
            |> StripeAccount.changeset(%{school_id: school.id})
            |> Repo.insert()
          end

        %{school | stripe_account: stripe_account}
      end)
    else
      Ecto.Changeset.apply_action(changeset, :insert)
    end
  end

  def is_superadmin?(user) do
    Mix.env() == :test || user.id in Application.get_env(:flight, :superadmin_ids)
  end
end

defmodule Flight.Accounts do
  import Ecto.Query, warn: false
  alias Flight.Repo

  alias Flight.Accounts.{User, UserRole, Role, FlyerCertificate, Invitation}
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

  def create_user(attrs, school_context) do
    attrs =
      attrs
      |> Poison.encode!()
      |> Poison.decode!()

    changeset =
      %User{}
      |> SchoolScope.school_changeset(school_context)
      |> User.create_changeset(attrs)

    if changeset.valid? do
      case Flight.Billing.create_stripe_customer(Ecto.Changeset.get_field(changeset, :email)) do
        {:ok, customer} ->
          changeset
          |> User.stripe_customer_changeset(%{stripe_customer_id: customer.id})
          |> Repo.insert()

        error ->
          error
      end
    else
      {:error, changeset}
    end
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

  def accept_invitation(invitation) do
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

    email = Ecto.Changeset.get_field(changeset, :email)

    user = get_user_by_email(email, school_context)

    if !user do
      case Repo.insert(changeset) do
        {:ok, invitation} = payload ->
          send_invitation_email(invitation)
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

  def create_user_from_invitation(user_data, invitation) do
    invitation = Repo.preload(invitation, :school)

    {:ok, result} =
      Repo.transaction(fn ->
        case create_user(user_data, invitation.school) do
          {:ok, user} ->
            accept_invitation(invitation)
            role = get_role(invitation.role_id)
            assign_roles(user, [role])

            {:ok, user}

          error ->
            error
        end
      end)

    result
  end

  def send_invitation_email(invitation) do
    Flight.Email.invitation_email(invitation)
    |> Flight.Mailer.deliver_later()
  end
end

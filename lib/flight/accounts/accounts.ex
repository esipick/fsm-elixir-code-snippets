defmodule Flight.Accounts do
  import Flight.Auth.Authorization
  import Ecto.Query, warn: false

  alias Flight.Repo
  alias Flight.Auth.Permission

  alias Flight.Accounts.{
    User,
    UserRole,
    Role,
    FlyerCertificate,
    Invitation,
    PasswordReset,
    School,
    SchoolInvitation,
    StripeAccount,
    UserInstructor,
    SchoolOnboarding
  }

  alias Flight.SchoolScope

  require Flight.Accounts.Role
  require Logger
  import Pipe

  def get_aircrafts(school_context) do
    Flight.Scheduling.Aircraft
    |> SchoolScope.scope_query(school_context)
    |> where([u], u.archived == false)
    |> Repo.all()
  end

  def get_aircrafts_only(school_context) do
    Flight.Scheduling.Aircraft
    |> SchoolScope.scope_query(school_context)
    |> where([u], u.simulator == false and u.archived == false)
    |> Repo.all()
  end

  def get_simulators_only(school_context) do
    Flight.Scheduling.Aircraft
    |> SchoolScope.scope_query(school_context)
    |> where([u], u.simulator == true and u.archived == false)
    |> Repo.all()
  end

  def get_school_user_by_id(id, school_context) do
    User
    |> SchoolScope.scope_query(school_context)
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_school_users_by_roles(school_id, roles) do
    from(
        u in User,
        distinct: u.id,
        inner_join: r in assoc(u, :roles),
        where: u.archived == false and u.school_id == ^school_id,
        where: r.slug in ^roles
      )
    |> Repo.all
  end

  def dangerous_get_user(nil), do: nil
  def dangerous_get_user(id), do: Repo.get(User, id)

  # In db table user_instructors, records are saved such as the instructor id goes to user_id column and the user_id goes to instructor_id column
  def get_student_instructor_ids(nil), do: []
  def get_student_instructor_ids(student_id) do
    UserInstructor
    |> where([ui], ui.user_id == ^student_id)
    |> select([ui], ui.instructor_id)
    |> Repo.all
  end

  def get_instructor_student_ids(nil), do: []
  def get_instructor_student_ids(instructor_id) do
    UserInstructor
    |> where([ui], ui.instructor_id == ^instructor_id)
    |> select([ui], ui.user_id)
    |> Repo.all
  end

  def delete_user_instructor(user_id, instructor_id) when is_nil(user_id) or is_nil(instructor_id), do: {:ok, :done}
  def delete_user_instructor(user_id, instructor_id) do
    from(ui in UserInstructor, where: ui.user_id == ^instructor_id and ui.instructor_id == ^user_id)
    |> Repo.delete_all
  end

  def insert_user_instructor(user_id, instructor_id) when is_nil(user_id) or is_nil(instructor_id), do: {:error, "Invalid User or Instructor."}
  def insert_user_instructor(user_id, instructor_id) do
    with nil <- Repo.get_by(UserInstructor, instructor_id: user_id, user_id: instructor_id) do
      %UserInstructor{}
      |> UserInstructor.changeset(%{user_id: instructor_id, instructor_id: user_id})
      |> Repo.insert
    end
  end


  def get_main_instructor_student_ids(nil), do: []
  def get_main_instructor_student_ids(instructor_id) do
    User
    |> select([u], u.id)
    |> where([u], u.archived == false and u.main_instructor_id == ^instructor_id)
    |> Repo.all
  end

  def dangerous_get_active_user(id) do
    User
    |> where([u], u.id == ^id)
    |> where([u], u.archived == false)
    |> Repo.one()
  end

  def get_directory_users_visible_to_user(%{assigns: %{current_user: user}} = conn) do
    user = Repo.preload(user, :roles)

    roles =
      Enum.reduce(user.roles, MapSet.new(), fn role, acc ->
        MapSet.union(acc, MapSet.new(roles_visible_to(role.slug)))
      end)
      |> MapSet.to_list()
      |> Enum.map(&Atom.to_string/1)

    users =
      from(
        u in User,
        distinct: u.id,
        inner_join: r in assoc(u, :roles),
        where: u.archived == false,
        where: r.slug in ^roles
      )
      |> default_users_query(conn)
      |> Repo.all()

    if Enum.find(users, &(&1.id == user.id)) do
      users
    else
      [user | users]
    end
  end

  def roles_visible_to("student") do
    [:instructor, :admin, :dispatcher, :mechanic]
  end

  def roles_visible_to("instructor") do
    [:student, :instructor, :admin, :dispatcher, :mechanic]
  end

  def roles_visible_to("renter") do
    [:admin, :dispatcher, :instructor]
  end

  def roles_visible_to("admin") do
    [:admin, :student, :renter, :instructor, :dispatcher, :mechanic]
  end

  def roles_visible_to("dispatcher") do
    [:student, :renter, :instructor, :dispatcher, :mechanic]
  end

  def roles_visible_to("mechanic") do
    [:instructor, :admin, :dispatcher, :mechanic]
  end

  def get_users(school_context) do
    User
    |> default_users_query(school_context)
    |> Repo.all()
  end

  def get_user_count(role, school_context) do
    from(
      u in User,
      where: u.archived == false,
      inner_join: r in assoc(u, :roles),
      where: r.id == ^role.id
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.aggregate(:count, :id)
  end

  def get_user(id, school_context) do
    User
    |> default_users_query(school_context)
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_user_regardless(id, school_context) do
    User
    |> all_users_query(school_context)
    |> where([u], u.id == ^id)
    |> Repo.one()
  end

  def get_user(id, roles, school_context) do
    from(
      u in User,
      inner_join: r in assoc(u, :roles),
      where: r.slug in ^roles,
      where: u.id == ^id
    )
    |> default_users_query(school_context)
    |> SchoolScope.scope_query(school_context)
    |> Repo.one()
  end

  def get_user_by_email(email) when is_nil(email) or email == "", do: nil

  def get_user_by_email(email) do
    User
    |> where([u], u.email == ^String.downcase(email))
    |> Repo.one()
  end

  def create_user(
        attrs,
        school_context,
        requires_stripe_account? \\ true,
        stripe_token \\ nil,
        user \\ %User{}
      ) do
    Flight.Accounts.CreateUserWithInvitation.create_user(
      attrs,
      school_context,
      requires_stripe_account?,
      stripe_token,
      user
    )
  end

  def user_changeset(user, attrs, school_context) do
    user
    |> SchoolScope.school_changeset(school_context)
    |> User.create_changeset(attrs)
  end

  def api_update_user_profile(
        %User{} = user,
        attrs,
        aircrafts,
        flyer_certificates,
        instructors
      ) do
    update_user_profile(
      user,
      attrs,
      nil,
      aircrafts,
      flyer_certificates,
      instructors,
      &User.api_update_changeset/6
    )
  end

  defp update_user_profile(
         user,
         attrs,
         role_slugs,
         aircraft_ids,
         flyer_certificate_slugs,
         instructor_ids,
         changeset_func
       ) do
    user =
      Repo.preload(user, [:roles, :aircrafts, :flyer_certificates, :instructors, :main_instructor])

    instructor_ids = instructor_ids || []
    instructor_ids =
      if user.main_instructor_id != nil do
        [user.main_instructor_id | instructor_ids]

      else
        instructor_ids
      end
      |> Enum.uniq

    {valid_roles?, roles} =
      if role_slugs do
        roles = Repo.all(from(r in Role, where: r.slug in ^role_slugs))
        valid_roles? = Enum.count(role_slugs) == Enum.count(roles)
        {valid_roles?, roles}
      else
        {true, nil}
      end

    {valid_aircrafts?, aircrafts, invalid_aircraft_ids} =
      case aircraft_ids do
        nil ->
          {true, nil, []}

        [] ->
          {true, [], []}

        aircraft_ids ->
          aircrafts =
            Repo.all(from(r in Flight.Scheduling.Aircraft, where: r.id in ^aircraft_ids))

          invalid_aircraft_ids =
            Enum.filter(aircraft_ids, fn id ->
              aircraft = Enum.find(aircrafts, fn aircraft -> aircraft.id == id end)
              aircraft.archived
            end)

          valid_aircrafts? =
            Enum.count(aircraft_ids) == Enum.count(aircrafts) and invalid_aircraft_ids == []

          {valid_aircrafts?, aircrafts, invalid_aircraft_ids}
      end

    {valid_certs?, certs} =
      if flyer_certificate_slugs do
        certs = Repo.all(from(c in FlyerCertificate, where: c.slug in ^flyer_certificate_slugs))
        valid_certs? = Enum.count(flyer_certificate_slugs) == Enum.count(certs)
        {valid_certs?, certs}
      else
        {true, nil}
      end

    {valid_instructors?, instructors, invalid_instructor_ids} =
      case instructor_ids do
        nil ->
          {true, nil, []}

        [] ->
          {true, [], []}

        instructor_ids ->
          instructors = Repo.all(from(r in User, where: r.id in ^instructor_ids))

          invalid_instructor_ids =
            Enum.filter(instructor_ids, fn id ->
              instructor = Enum.find(instructors, fn instructor -> instructor.id == id end)
              instructor.archived
            end)

          valid_instructors? =
            Enum.count(instructor_ids) == Enum.count(instructors) and invalid_instructor_ids == []

          {valid_instructors?, instructors, invalid_instructor_ids}
      end

    valid_main_instructor? =
      case attrs["main_instructor_id"] do
        id when id in ["", nil] ->
          true

        id ->
          main_instructor = Repo.one(from(r in User, where: r.id == ^id))
          !main_instructor.archived and id != user.id
      end

    avatar = user.avatar

    cond do
      !valid_roles? ->
        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], [], [], []),
           :roles,
           "are not all known: #{Enum.join(role_slugs, ", ")}"
         )}

      !valid_aircrafts? ->
        message =
          case invalid_aircraft_ids do
            [] ->
              "are not all known: #{Enum.join(role_slugs, ", ")}"

            invalid_aircraft_ids ->
              "should be active: #{Enum.join(invalid_aircraft_ids, ", ")}"
          end

        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], [], [], []),
           :aircrafts,
           message
         )}

      !valid_certs? ->
        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], [], [], []),
           :flyer_certificates,
           "are not all known: #{Enum.join(flyer_certificate_slugs, ", ")}"
         )}

      !valid_instructors? ->
        message =
          case invalid_instructor_ids do
            [] ->
              "are not all known: #{Enum.join(role_slugs, ", ")}"

            invalid_instructor_ids ->
              "should be active: #{Enum.join(invalid_instructor_ids, ", ")}"
          end

        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], [], [], []),
           :instructors,
           message
         )}

      !valid_main_instructor? ->
        {:error,
         Ecto.Changeset.add_error(
           changeset_func.(user, attrs, [], [], [], []),
           :main_instructor_id,
           "should be active"
         )}

      true ->
        result =
          user
          |> changeset_func.(attrs, roles, aircrafts, certs, instructors)
          |> Repo.update()

        case result do
          {:ok, updated_user} ->
            if attrs["delete_avatar"] == "1" and avatar do
              Flight.AvatarUploader.delete({avatar, updated_user})
            end

            instructor_exists = user.main_instructor_id != nil
            is_main_instructor_updated? = updated_user.main_instructor_id != user.main_instructor_id

            if is_main_instructor_updated? && instructor_exists do
              delete_user_instructor(user.id, user.main_instructor_id)
            end

            if is_main_instructor_updated? do
              insert_user_instructor(user.id, updated_user.main_instructor_id)
            end

            {:ok, updated_user}

          error ->
            error
        end
    end
  end

  def admin_update_user_profile(
        %User{} = user,
        attrs,
        role_slugs,
        aircrafts,
        flyer_certificate_slugs,
        instructors
      ) do
    update_user_profile(
      user,
      attrs,
      role_slugs,
      aircrafts,
      flyer_certificate_slugs,
      instructors,
      &User.admin_update_changeset/6
    )
  end

  def regular_user_update_profile(%User{} = user, attrs) do
    avatar = user.avatar

    result =
      user
      |> User.regular_user_update_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, user} ->
        if attrs["delete_avatar"] == "1" and avatar do
          Flight.AvatarUploader.delete({avatar, user})
        end

        {:ok, user}

      error ->
        error
    end
  end

  def archive_user(%User{} = user) do
    user
    |> User.archive_changeset(%{archived: true, password_token: Flight.Random.string(10)})
    |> Repo.update()
  end

  def restore_user(%User{} = user) do
    user
    |> User.archive_changeset(%{archived: false})
    |> Repo.update()
  end

  def archive_school(%School{} = school) do
    school
    |> School.archive_changeset(%{archived: true})
    |> Repo.update()
  end

  def check_password(user, password) do
    Comeonin.Bcrypt.check_pass(user, password)
  end

  def set_password(user, password) do
    user
    |> User.update_password_changeset(%{password: password})
    |> Repo.update()
  end

  def update_password(user, %{"password" => password, "new_password" => new_password}) do
    with {:ok, user} <- check_password(user, password),
         %{valid?: true} = user <- User.update_password_changeset(user, %{password: new_password}) do
      user
      |> set_password(new_password)
    else
      {:error, %{} = changeset} ->
        {:error, changeset}

      {:error, "invalid password"} ->
        {:error,
          %Ecto.Changeset{
            valid?: false,
            errors: [current_password: {"is invalid", []}],
            types: %{current_password: :string}
          }}

      {:error, _} ->
        {:error,
         %Ecto.Changeset{
           valid?: false,
           errors: [password: {"is invalid", []}],
           types: %{password: :string}
         }}

      changeset ->
        {:error, changeset}
    end
  end

  def update_password(_, %{"password" => _}) do
    {:error,
     %Ecto.Changeset{
       errors: [new_password: {"can't be empty", []}],
       types: %{new_password: :string}
     }}
  end

  def update_password(_, %{"new_password" => _}) do
    {:error,
     %Ecto.Changeset{errors: [password: {"can't be empty", []}], types: %{password: :string}}}
  end

  def create_password_reset(user) do
    %PasswordReset{}
    |> PasswordReset.changeset(%{user_id: user.id, token: Flight.Random.hex(60)})
    |> Flight.Repo.insert()
  end

  def get_password_reset(%User{} = user) do
    from(
      r in PasswordReset,
      where: r.user_id == ^user.id,
      where: r.inserted_at > ^Timex.shift(Timex.now(), days: -15),
      order_by: [desc: r.inserted_at],
      preload: [:user],
      limit: 1
    )
    |> Flight.Repo.one()
  end

  def get_password_reset_from_token(token) when is_binary(token) do
    from(
      r in PasswordReset,
      where: r.token == ^token,
      where: r.inserted_at > ^Timex.shift(Timex.now(), days: -15),
      order_by: [desc: r.inserted_at],
      preload: [:user],
      limit: 1
    )
    |> Flight.Repo.one()
  end

  ###
  # Schools
  ###

  def admin_update_school(%School{} = school, attrs) do
    school
    |> School.admin_changeset(attrs)
    |> Repo.update()
  end

  def get_school_with_fallback(id, fallback_id) do
    case school = get_school(id) do
      nil -> get_school(fallback_id)
      _ -> school
    end
  end

  def get_schools_without_selected(school_id) do
    School
    |> where([s], s.archived == false and s.id != ^school_id)
    |> Repo.all()
  end

  def get_schools() do
    School
    |> where([s], s.archived == false)
    |> Repo.all()
  end

  def get_school(id) when is_nil(id), do: nil

  def get_school(id) do
    School
    |> where([s], s.archived == false)
    |> where([s], s.id == ^id)
    |> Repo.one()
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
      :certificate_number,
      :inserted_at,

      :date_of_birth,
      :gender,
      :emergency_contact_no,
      :d_license_no,
      :d_license_expires_at,
      :d_license_country,
      :d_license_state,
      :passport_no,
      :passport_expires_at,
      :passport_country,
      :passport_issuer_name,
      :last_faa_flight_review_at,
      :renter_policy_no,
      :renter_insurance_expires_at,

#      :pilot_current_certificate,
#      :pilot_aircraft_categories,
#      :pilot_class,
#      :pilot_ratings,
#      :pilot_endorsements,
#      :pilot_certificate_number,
#      :pilot_certificate_expires_at
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

  def editable_fields_for_role_slug("dispatcher") do
    [:email, :first_name, :last_name, :phone_number]
  end

  def editable_fields_for_role_slug("mechanic") do
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

  def get_user_roles(conn) do
    user = conn.assigns.current_user
    roles = Role |> Flight.Repo.all()

    if user_can?(user, [Permission.new(:admins, :modify, :all)]) do
      roles
    else
      Enum.filter(roles, fn r -> !(r.slug in ["admin", "dispatcher"]) end)
    end
  end

  def users_with_role_query(%{slug: "user"}, search_term, from_date, to_date, school_context) do
    User
    |> Flight.Accounts.Search.User.run(search_term, from_date, to_date)
    |> default_users_query(school_context)
    |> preload(:roles)
  end

  def users_with_role_query(role, search_term, from_date, to_date, school_context) do
    role
    |> Ecto.assoc(:users)
    |> Flight.Accounts.Search.User.run(search_term, from_date, to_date)
    |> default_users_query(school_context)
  end

  def instructor_students_query(query, instructor_id) do
    from(u in query,
      join: i in assoc(u, :instructors),
      where: i.id == ^instructor_id
    )
  end

  def archived_users_with_role_query(%{slug: "user"}, search_term, from_date, to_date, school_context) do
    User
    |> Flight.Accounts.Search.User.run(search_term, from_date, to_date)
    |> archived_users_query(school_context)
    |> preload(:roles)
  end

  def archived_users_with_role_query(role, search_term, from_date, to_date, school_context) do
    role
    |> Ecto.assoc(:users)
    |> Flight.Accounts.Search.User.run(search_term, from_date, to_date)
    |> archived_users_query(school_context)
  end

  def users_with_roles([], _school_context) do
    []
  end

  def users_with_roles(roles, school_context, params \\ %{}) do
    case roles do
      [] ->
        []

      _ ->
        roles
        |> Ecto.assoc(:users)
        |> default_users_query(school_context)
        |> pass_unless(params["user_id"], &where(&1, [t], t.id == ^params["user_id"]))
        |> Repo.all()
    end
  end

  def default_users_query(query, school_context) do
    from(
      u in query,
      where: u.archived == false,
      order_by: u.last_name
    )
    |> SchoolScope.scope_query(school_context)
  end

  def all_users_query(query, school_context) do
    from(
      u in query,
      order_by: u.last_name
    )
    |> SchoolScope.scope_query(school_context)
  end

  def archived_users_query(query, school_context) do
    from(
      u in query,
      where: u.archived == true,
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

  def has_aircraft?(user, aircraft_id) do
    user = Repo.preload(user, :aircrafts)

    user.aircrafts
    |> Enum.map(& &1.id)
    |> Enum.member?(aircraft_id)
  end

  def has_instructor?(user, instructor_id) do
    user = Repo.preload(user, :instructors)

    user.instructors
    |> Enum.map(& &1.id)
    |> Enum.member?(instructor_id)
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

  def visible_invitations_with_role("user", school_context) do
    from(
      i in Invitation,
      inner_join: r in assoc(i, :role),
      where: is_nil(i.accepted_at),
      order_by: [desc: i.inserted_at],
      preload: [:role]
    )
    |> SchoolScope.scope_query(school_context)
    |> Repo.all()
  end

  def visible_invitations_with_role(role_slug, school_context) do
    from(
      i in Invitation,
      inner_join: r in assoc(i, :role),
      where: is_nil(i.accepted_at),
      where: r.slug == ^role_slug,
      order_by: [desc: i.inserted_at]
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
    Flight.Accounts.CreateUserWithInvitation.create_invitation(attrs, school_context)
  end

  def create_user_from_invitation(user_data, stripe_token, invitation) do
    Flight.Accounts.AcceptInvitation.run(user_data, stripe_token, invitation)
  end

  def delete_invitation!(invitation), do: Repo.delete(invitation)

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
      where: is_nil(i.accepted_at),
      order_by: [desc: i.inserted_at]
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

    user = get_user_by_email(email)

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
            create_school_onboarding(school)
            Flight.General.create_category_at_lms(school)
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

  def delete_school_invitation!(invitation), do: Repo.delete(invitation)

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
    user.id in Application.get_env(:flight, :superadmin_ids, [])
  end

  def create_school_onboarding(school) do
    SchoolOnboarding.create(%{school_id: school.id})
  end

end

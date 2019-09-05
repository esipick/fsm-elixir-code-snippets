Faker.start()

role_name = List.first(System.argv())

user_role = case role_name do
  "instructor" ->
    Flight.Accounts.Role.instructor
  "renter" ->
    Flight.Accounts.Role.renter
  _ ->
    Flight.Accounts.Role.student
end

Enum.each(0..99, fn(i) ->
  school = Flight.Repo.one(Flight.Accounts.School)
  school_context = %Plug.Conn{assigns: %{current_user: %{school_id: school.id}}}

  phone_number =
    Integer.to_string(Enum.random(100..999)) <> "-" <>
    Integer.to_string(Enum.random(100..999)) <> "-" <>
    Integer.to_string(Enum.random(1000..9999))

  user_data = %{
    email: Faker.Internet.email,
    first_name: Faker.Name.first_name,
    last_name: Faker.Name.last_name,
    phone_number: phone_number,
    school_id: school.id,
    timezone: "America/Denver",
    password: "password"
  }

  case Flight.Accounts.create_user(user_data, school_context, false) do
    {:ok, user} ->
      Flight.Accounts.assign_roles(user, [user_role])
    _ ->
      IO.puts("err")
  end
end)
